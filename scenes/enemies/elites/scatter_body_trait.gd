class_name ScatterBodyTrait
extends EliteTrait
## Breaks into blocks that fly across the screen one at a time, then rebuilds; while whole only its
## eye can be hit, and only for a moment after the rebuild. Counter: learn the block order, then shoot the eye.

enum Mode { OPEN, WARN, OUT, BACK }

const PIECE_SCENE := preload("res://scenes/enemies/elites/scatter_piece.tscn")
const EYE_SCENE := preload("res://assets/art/dusk_armada/elites/eye.tscn")
const COLUMNS := 4
const BLOCK := 15.0
const STRIDES := [5, 7, 3, 1]
const LANE_MIN := 60.0
const LANE_MAX := 480.0

@export var pieces := 12
@export var piece_speed := 520.0
@export var piece_gap := 0.18
@export var eye_open := 2.5
## Seconds the blocks flash before they fly.
@export var warn_time := 0.7


## Where block `i` of `n` sits in the body, relative to the elite.
static func grid_offset(i: int, n: int) -> Vector2:
	var rows := ceili(float(n) / COLUMNS)
	var col := i % COLUMNS
	var row := i / COLUMNS
	return Vector2((col - (COLUMNS - 1) / 2.0) * BLOCK, (row - (rows - 1) / 2.0) * BLOCK)


## The x on the bottom of the screen that block `i` of `n` flies at: a fixed shuffle of the lanes.
static func lane_x(i: int, n: int) -> float:
	if n <= 1:
		return (LANE_MIN + LANE_MAX) * 0.5
	var stride := 1
	for s: int in STRIDES:
		if _gcd(s, n) == 1:
			stride = s
			break
	return lerpf(LANE_MIN, LANE_MAX, float((i * stride) % n) / (n - 1))


static func _gcd(a: int, b: int) -> int:
	return a if b == 0 else _gcd(b, a % b)


func begin(elite: Elite) -> void:
	var st := state(elite)
	st["mode"] = Mode.OPEN
	st["t"] = 0.0
	st["next"] = 0
	var list: Array[ScatterPiece] = []
	st["pieces"] = list
	for i in pieces:
		var piece: ScatterPiece = PIECE_SCENE.instantiate()
		piece.home = grid_offset(i, pieces)
		piece.position = elite.position + piece.home
		list.append(piece)
		elite.entities.add_child.call_deferred(piece)
	var eye: Node2D = EYE_SCENE.instantiate()
	elite.add_child(eye)
	eye.call("set_open", true)
	st["eye"] = eye
	elite.get_node("Visual").visible = false


func tick(elite: Elite, delta: float) -> void:
	var st := state(elite)
	var list: Array[ScatterPiece] = st["pieces"]
	if list.any(func(p: ScatterPiece) -> bool: return not p.is_inside_tree()):
		return
	st["t"] += delta
	var mode: Mode = st["mode"]
	match mode:
		Mode.OPEN:
			_follow(elite, list)
			if st["t"] >= eye_open:
				_enter(elite, Mode.WARN)
		Mode.WARN:
			_follow(elite, list)
			if st["t"] >= warn_time:
				_enter(elite, Mode.OUT)
		Mode.OUT:
			_scatter(elite, list, delta)
		Mode.BACK:
			_rebuild(elite, list, delta)


func absorb(elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	return amount if state(elite).get("mode") == Mode.OPEN else 0


func end(elite: Elite) -> void:
	var list: Array = state(elite).get("pieces", [])
	for piece: Variant in list:
		if is_instance_valid(piece):
			(piece as Node).queue_free()
	list.clear()
	_set_solid(elite, true)
	elite.can_fire = true
	elite.get_node("Visual").visible = true


func _enter(elite: Elite, mode: Mode) -> void:
	var st := state(elite)
	st["mode"] = mode
	st["t"] = 0.0
	st["next"] = 0
	var list: Array[ScatterPiece] = st["pieces"]
	for piece in list:
		piece.set_flash(mode == Mode.WARN)
	(st["eye"] as Node).call("set_open", mode == Mode.OPEN)
	(st["eye"] as CanvasItem).visible = mode != Mode.OUT and mode != Mode.BACK
	_set_solid(elite, mode != Mode.OUT and mode != Mode.BACK)
	elite.can_fire = mode == Mode.OPEN


func _follow(elite: Elite, list: Array[ScatterPiece]) -> void:
	for piece in list:
		if piece.mode == ScatterPiece.Mode.HOME:
			piece.global_position = elite.global_position + piece.home


## Launches a block every `piece_gap`; once all are off screen the rebuild starts.
func _scatter(elite: Elite, list: Array[ScatterPiece], delta: float) -> void:
	var st := state(elite)
	var next: int = st["next"]
	while next < list.size() and st["t"] >= next * piece_gap:
		var piece := list[next]
		piece.direction = piece.global_position.direction_to(Vector2(lane_x(next, list.size()), 1000.0))
		piece.set_mode(ScatterPiece.Mode.OUT)
		next += 1
	st["next"] = next
	var all_gone := true
	for piece in list:
		if piece.mode == ScatterPiece.Mode.HOME:
			piece.global_position = elite.global_position + piece.home
			all_gone = false
		elif piece.mode == ScatterPiece.Mode.OUT:
			all_gone = false
			if piece.fly_out(delta, piece_speed):
				piece.set_mode(ScatterPiece.Mode.GONE)
	if all_gone:
		_enter(elite, Mode.BACK)


## Sends the blocks back in the same order, along the line they left by.
func _rebuild(elite: Elite, list: Array[ScatterPiece], delta: float) -> void:
	var st := state(elite)
	var next: int = st["next"]
	while next < list.size() and st["t"] >= next * piece_gap:
		list[next].set_mode(ScatterPiece.Mode.BACK)
		next += 1
	st["next"] = next
	var all_home := true
	for piece in list:
		if piece.mode == ScatterPiece.Mode.BACK:
			if piece.fly_back(delta, piece_speed, elite.global_position + piece.home):
				piece.set_mode(ScatterPiece.Mode.HOME)
			else:
				all_home = false
		elif piece.mode == ScatterPiece.Mode.GONE:
			all_home = false
	if all_home and next >= list.size():
		_enter(elite, Mode.OPEN)


## Scattered, the elite can't be hit or rammed; whole, it can.
func _set_solid(elite: Elite, solid: bool) -> void:
	elite.hurtbox.set_deferred(&"monitorable", solid)
	elite.get_node("ContactHitbox").set_deferred(&"monitoring", solid)
