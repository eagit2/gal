class_name FireBar
extends Node2D
## A chain of fireballs spinning around its anchor enemy. Segments hurt the player on contact (like
## enemy shots) and cannot be shot down; the bar goes when the anchor does.

const GROW_TIME := 0.5
const SPIN_EASE := 5.0
const WOBBLE_PHASE := 0.6

var segments := 6
var ball_radius := 12.0
var spacing := 26.0
var spin_speed := 1.6
var wobble := 24.0
var wobble_speed := 3.0
var reverse_every := 5.0

var _anchor: Node2D
var _t := 0.0
var _angle := 0.0
var _dir := 1.0
var _spin := 0.0
var _grow := 0.0
var _hitboxes: Array[Hitbox] = []
var _armed: Array[bool] = []

@onready var _visual: Node2D = $Visual


## Local offset of segment `index` (0 = nearest the anchor) for a bar pointing along `angle`:
## out along the bar, plus a sideways sine so the line meanders.
static func segment_offset(index: int, angle: float, t: float, spacing_px: float, wobble_px: float, wobble_rate: float) -> Vector2:
	var along := Vector2.from_angle(angle) * spacing_px * (index + 1)
	var side := Vector2.from_angle(angle + PI / 2.0) * sin(t * wobble_rate + index * WOBBLE_PHASE) * wobble_px
	return along + side


func setup(anchor: Node2D) -> void:
	_anchor = anchor
	top_level = true
	global_position = anchor.global_position
	_angle = randf() * TAU
	_dir = 1.0 if randf() < 0.5 else -1.0


func _ready() -> void:
	for i in segments:
		var box := Hitbox.new()
		box.collision_layer = 8
		box.collision_mask = 1
		box.monitorable = false
		box.monitoring = false
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = ball_radius
		shape.shape = circle
		box.add_child(shape)
		add_child(box)
		_hitboxes.append(box)
		_armed.append(false)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_anchor):
		queue_free()
		return
	global_position = _anchor.global_position
	if GameState.freeze_left > 0.0:
		return
	_t += delta
	_grow = minf(1.0, _grow + delta / GROW_TIME)
	if reverse_every > 0.0 and fmod(_t, reverse_every) < delta:
		_dir = -_dir
	_spin = move_toward(_spin, _dir * spin_speed, SPIN_EASE * delta)
	_angle += _spin * delta
	var points := PackedVector2Array()
	for i in segments:
		var offset := segment_offset(i, _angle, _t, spacing, wobble, wobble_speed)
		points.append(offset)
		_hitboxes[i].position = offset
		# Segments switch on as the bar unfurls, so a fresh dive gives a moment of warning.
		var live := _grow >= float(i + 1) / segments
		if live != _armed[i]:
			_armed[i] = live
			_hitboxes[i].set_deferred(&"monitoring", live)
	_visual.call("show_chain", points, _grow, ball_radius)
