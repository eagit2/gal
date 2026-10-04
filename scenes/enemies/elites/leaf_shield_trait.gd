class_name LeafShieldTrait
extends EliteTrait
## Leaves orbit the elite and soak up your shots, then all launch at you at once after a red flash.
## Counter: sidestep the launch, then shoot the bare elite while the leaves regrow.

enum Mode { HOLD, LAUNCH, REGROW }

const LEAF_SCENE := preload("res://scenes/enemies/elites/leaf.tscn")

@export var leaves := 6
@export var orbit_radius := 60.0
@export var hold_time := 3.0
@export var launch_speed := 300.0
@export var regrow := 2.0
## Radians per second the ring turns.
@export var spin := 1.8
## Seconds of red flashing and fast spinning before the launch.
@export var telegraph := 0.8


## Where leaf `i` of `n` is on a ring of `radius` around `center`, turned by `angle`.
static func orbit_pos(center: Vector2, radius: float, angle: float, i: int, n: int) -> Vector2:
	return center + Vector2.from_angle(angle + TAU * i / maxi(n, 1)) * radius


func begin(elite: Elite) -> void:
	var st := state(elite)
	st["mode"] = Mode.HOLD
	st["t"] = 0.0
	st["angle"] = 0.0
	var list: Array[LeafNode] = []
	st["leaves"] = list
	for i in leaves:
		var leaf: LeafNode = LEAF_SCENE.instantiate()
		leaf.position = orbit_pos(elite.position, orbit_radius, 0.0, i, leaves)
		list.append(leaf)
		elite.entities.add_child.call_deferred(leaf)


func tick(elite: Elite, delta: float) -> void:
	var st := state(elite)
	var list: Array[LeafNode] = st["leaves"]
	if list.any(func(l: LeafNode) -> bool: return not l.is_inside_tree()):
		return
	if not st.get("armed", false):
		st["armed"] = true
		_set_all(list, LeafNode.Mode.GUARD)
	st["t"] += delta
	var mode: Mode = st["mode"]
	var warn: bool = mode == Mode.HOLD and st["t"] >= hold_time - telegraph
	st["angle"] += delta * spin * (3.0 if warn else 1.0)
	match mode:
		Mode.HOLD:
			_orbit(elite, list)
			for leaf in list:
				leaf.set_warn(warn)
			if st["t"] >= hold_time:
				_launch(elite, list)
		Mode.LAUNCH:
			var left := false
			for leaf in list:
				if leaf.mode == LeafNode.Mode.FLY:
					if leaf.fly(delta):
						leaf.set_mode(LeafNode.Mode.GONE)
					else:
						left = true
			if not left:
				st["mode"] = Mode.REGROW
				st["t"] = 0.0
				_set_all(list, LeafNode.Mode.GROW)
		Mode.REGROW:
			_orbit(elite, list)
			for leaf in list:
				leaf.set_growth(st["t"] / maxf(regrow, 0.01))
			if st["t"] >= regrow:
				st["mode"] = Mode.HOLD
				st["t"] = 0.0
				_set_all(list, LeafNode.Mode.GUARD)


## The ring shields the elite while it holds; once it launches the elite is open.
func absorb(elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	return 0 if state(elite).get("mode") == Mode.HOLD else amount


func end(elite: Elite) -> void:
	var list: Array = state(elite).get("leaves", [])
	for leaf: Variant in list:
		if is_instance_valid(leaf):
			(leaf as Node).queue_free()
	list.clear()


func _orbit(elite: Elite, list: Array[LeafNode]) -> void:
	for i in list.size():
		var leaf := list[i]
		leaf.global_position = orbit_pos(elite.global_position, orbit_radius, state(elite)["angle"], i, list.size())
		leaf.rotation = state(elite)["angle"] + TAU * i / list.size() + PI / 2


## All leaves at once, each aimed at where the player is now.
func _launch(elite: Elite, list: Array[LeafNode]) -> void:
	var st := state(elite)
	st["mode"] = Mode.LAUNCH
	st["t"] = 0.0
	var goal := elite.global_position + Vector2.DOWN * 600.0
	if is_instance_valid(elite.target):
		goal = elite.target.global_position
	for leaf in list:
		leaf.set_warn(false)
		leaf.velocity = leaf.global_position.direction_to(goal) * launch_speed
		leaf.set_mode(LeafNode.Mode.FLY)


func _set_all(list: Array[LeafNode], mode: LeafNode.Mode) -> void:
	for leaf in list:
		leaf.set_mode(mode)
		leaf.set_warn(false)
		if mode == LeafNode.Mode.GROW:
			leaf.set_growth(0.0)
