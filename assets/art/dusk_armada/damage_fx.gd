class_name DamageFx
extends Node2D
## Hit feedback for the entity this visual belongs to: a white flash, a shake and sparks on
## every hit it survives; damaged frames and smoke once it is down to half health or less.
## It listens to the entity's Health node, so it doesn't depend on any movement script.

const FLASH_TIME := 0.12
const SHAKE_TIME := 0.15
## In texture pixels (sprites are drawn at 2x).
const SHAKE := 1.0

@export var sprite: FlapSprite
@export var sparks: CPUParticles2D
@export var smoke: CPUParticles2D
var _health: Health
var _flash := 0.0
var _shake := 0.0


func _ready() -> void:
	_health = _find_health()
	if _health:
		_health.damaged.connect(_on_damaged)
	set_process(false)


func _find_health() -> Health:
	var node := get_parent()
	while node:
		var health := node.get_node_or_null(^"Health") as Health
		if health:
			return health
		node = node.get_parent()
	return null


func _on_damaged(_amount: int) -> void:
	if _health.hp <= 0:
		return  # the explosion covers lethal hits
	_flash = FLASH_TIME
	_shake = SHAKE_TIME
	sparks.restart()
	if _health.hp * 2 <= _health.max_hp:
		sprite.show_damaged()
		smoke.emitting = true
	set_process(true)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_shake = maxf(0.0, _shake - delta)
	(sprite.material as ShaderMaterial).set_shader_parameter(&"flash", _flash / FLASH_TIME)
	sprite.offset = Vector2(randf_range(-SHAKE, SHAKE), randf_range(-SHAKE, SHAKE)).round() if _shake > 0.0 else Vector2.ZERO
	if _flash <= 0.0 and _shake <= 0.0:
		set_process(false)
