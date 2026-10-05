class_name HivePod
extends Node2D
## The Hive Carrier's pod: hangs on a tether below the elite and hatches `swarm` enemies that dive
## straight at the player every `interval`. Shooting it down ends the swarms. If the carrier dies
## first it falls, crushing enemies on the way. Touching it costs a life.

const FOLLOW := 2.4
const FALL_ACCEL := 120.0
const MAX_FALL := 220.0
const BOTTOM := 1100.0
const CHARGE := 1.0
## Radius the pod's art is drawn at.
const ART_RADIUS := 30.0

var elite: Elite
var tethered := true
var _length := 120.0
var _radius := 52.0
var _hp := 30
var _swarm_def: EnemyDef
var _swarm := 3
var _interval := 6.0
var _timer := 3.0
var _fall := 0.0

@onready var _visual: Node2D = $Visual


func setup(towing: Elite, hp: int, length: float, swarm_def: EnemyDef, swarm: int, interval: float, radius := 52.0) -> void:
	elite = towing
	_radius = radius
	_hp = hp
	_length = length
	_swarm_def = swarm_def
	_swarm = swarm
	_interval = interval
	_timer = interval * 0.5
	position = towing.position + Vector2(0, length)


func _ready() -> void:
	($Health as Health).reset(_hp)
	_set_radius(_radius)
	$Health.died.connect(_on_died)
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: ($Health as Health).take_damage(5))


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	if not tethered:
		_fall = minf(_fall + FALL_ACCEL * delta, MAX_FALL)
		position.y += _fall * delta
		rotation += 0.6 * delta
		if position.y > BOTTOM:
			queue_free()
		return
	if not is_instance_valid(elite):
		drop()
		return
	position = position.lerp(elite.position + Vector2(0, _length), minf(1.0, FOLLOW * delta))
	_visual.call("set_tether", (elite.position + Vector2(0, 18) - position) / _visual.scale.x)
	if not elite.entered:
		return
	_timer -= delta
	_visual.call("set_charge", clampf(1.0 - _timer / CHARGE, 0.0, 1.0))
	if _timer <= 0.0:
		_timer = _interval
		_hatch()


func drop() -> void:
	if not tethered:
		return
	tethered = false
	_visual.call("set_tether", null)
	_visual.call("set_charge", 0.0)
	$Crusher.ignore = elite
	$Crusher.set_deferred(&"monitoring", true)


func _hatch() -> void:
	for i in _swarm:
		EnemySpawner.launch_at(_swarm_def, elite.difficulty, position + Vector2((i - (_swarm - 1) / 2.0) * 22.0, 20.0), elite.target, get_parent())


func _on_died() -> void:
	EventBus.scrap_dropped.emit(global_position, 6)
	EventBus.elite_trait_broken.emit(global_position)
	queue_free()


## Body, contact and crush shapes sized to `radius`, art scaled to match.
func _set_radius(radius: float) -> void:
	var body := CircleShape2D.new()
	body.radius = radius
	($Hurtbox/Shape as CollisionShape2D).shape = body
	var contact := CircleShape2D.new()
	contact.radius = radius * 0.85
	($ContactHitbox/Shape as CollisionShape2D).shape = contact
	($Crusher/Shape as CollisionShape2D).shape = contact
	_visual.scale = Vector2.ONE * radius / ART_RADIUS
