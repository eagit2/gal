class_name TowedRock
extends Node2D
## The Rock Hauler's giant rock. Hangs on a tether below the elite and lags behind its moves. Every
## 1/chunks of its hp breaks off a falling chunk. Shooting the tether's hurtbox cuts it loose: the
## rock then drifts down and off screen, crushing enemies on the way. Touching it costs a life.

const CHUNK_SCENE := preload("res://scenes/enemies/elites/rock_chunk.tscn")
const FOLLOW := 2.0
const FALL_ACCEL := 90.0
const MAX_FALL := 170.0
const BOTTOM := 1100.0
const RADIUS := 52.0
## Follow speed while swinging (stiffer, so the rock really sweeps).
const SWING_FOLLOW := 7.0
const SWING_RAMP := 0.6

var elite: Elite
var tethered := true
var _length := 96.0
var _chunks := 6
var _chunk_hp := 40
var _chunk_damage := 0
var _fall := 0.0
var _swinging := false
var _swing_time := 0.0
var _swing_speed := 2.2
var _swing_arc := 2.4
var _warn := 0.0
var _visual: Node2D

@onready var _health: Health = $Health
@onready var _tether: Hurtbox = $Tether
@onready var _body_shape: CircleShape2D = ($Hurtbox/Shape as CollisionShape2D).shape
@onready var _contact_shape: CircleShape2D = ($ContactHitbox/Shape as CollisionShape2D).shape
@onready var _tether_shape: RectangleShape2D = ($Tether/Shape as CollisionShape2D).shape


func setup(towing: Elite, hp: int, chunks: int, length: float) -> void:
	elite = towing
	_chunks = chunks
	_chunk_hp = maxi(1, hp / chunks)
	_length = length
	position = towing.position + Vector2(0, length)


func _ready() -> void:
	_visual = $Visual
	_health.reset(_chunk_hp * _chunks)
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_break_apart)
	($Tether/Health as Health).died.connect(cut)
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: _health.take_damage(_chunk_hp))
	_resize()


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	if tethered:
		if not is_instance_valid(elite):
			cut()
			return
		var goal := elite.position + Vector2(0, _length).rotated(_swing_angle(delta))
		position = position.lerp(goal, minf(1.0, (SWING_FOLLOW if _swinging else FOLLOW) * delta))
		# The tether's hurtbox covers only the exposed line between the rock's edge and the elite.
		var anchor := elite.position + Vector2(0, 18) - position
		var edge := anchor.normalized() * _body_shape.radius
		_tether.position = (edge + anchor) * 0.5
		_tether.rotation = anchor.angle() - PI / 2
		_tether_shape.size.y = maxf(4.0, (anchor - edge).length())
		_visual.call("set_tether", anchor)
	else:
		_fall = minf(_fall + FALL_ACCEL * delta, MAX_FALL)
		position.y += _fall * delta
		rotation += 0.4 * delta
		if position.y > BOTTOM:
			queue_free()


## Telegraph: the rock flashes red for `seconds` before it swings.
func warn(seconds: float) -> void:
	_warn = seconds


## Starts swinging back and forth across `arc` radians at `speed` rad/s around the elite. The
## rock now crushes enemies it sweeps through (not the elite).
func start_swing(speed: float, arc: float) -> void:
	if _swinging or not tethered:
		return
	_swinging = true
	_swing_speed = speed
	_swing_arc = minf(arc, 3.0)
	_warn = 0.0
	modulate = Color.WHITE
	$Crusher.ignore = elite
	$Crusher.set_deferred(&"monitoring", true)


## Angle of the swing from straight down after `t` seconds: the top angular speed is `speed`,
## eased in over SWING_RAMP so the rock doesn't snap sideways.
static func swing_angle_at(t: float, speed: float, arc: float) -> float:
	var half := maxf(arc, 0.01) * 0.5
	return sin(t * speed / half) * half * clampf(t / SWING_RAMP, 0.0, 1.0)


func _swing_angle(delta: float) -> float:
	if _warn > 0.0:
		_warn -= delta
		modulate = Color(1.6, 0.6, 0.6) if int(_warn * 10.0) % 2 == 0 else Color.WHITE
		if _warn <= 0.0:
			modulate = Color.WHITE
	if not _swinging:
		return 0.0
	_swing_time += delta
	return swing_angle_at(_swing_time, _swing_speed, _swing_arc)


func cut() -> void:
	if not tethered:
		return
	tethered = false
	_swinging = false
	modulate = Color.WHITE
	$Crusher.ignore = elite
	$Crusher.set_deferred(&"monitoring", true)
	_tether.queue_free()
	_visual.call("set_tether", null)
	EventBus.elite_trait_broken.emit(global_position)


func _on_damaged(amount: int) -> void:
	_chunk_damage += amount
	while _chunk_damage >= _chunk_hp and _health.hp > 0:
		_chunk_damage -= _chunk_hp
		_spawn_chunk()
	_resize()


func _spawn_chunk() -> void:
	var chunk: Node2D = CHUNK_SCENE.instantiate()
	chunk.position = position + Vector2.from_angle(randf_range(0.3, PI - 0.3)) * RADIUS * _fraction()
	get_parent().add_child.call_deferred(chunk)


func _fraction() -> float:
	return 0.35 + 0.65 * float(_health.hp) / float(_health.max_hp)


func _resize() -> void:
	var f := _fraction()
	_body_shape.radius = RADIUS * f
	_contact_shape.radius = RADIUS * f * 0.85
	_visual.call("set_size", f)


func _break_apart() -> void:
	_spawn_chunk()
	EventBus.scrap_dropped.emit(global_position, 6)
	if is_instance_valid(elite) and tethered:
		tethered = false
	queue_free()
