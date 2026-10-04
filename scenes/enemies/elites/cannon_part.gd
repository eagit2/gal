class_name CannonPart
extends Node2D
## A shoot-off cannon on the Iron Fortress: its own hit points and hurtbox, and a fire pattern
## picked by `kind` (the trait fires it). Emits `destroyed` once.

signal destroyed

var kind := 0
var hp := 40
var cooldown := 1.0

@onready var _health: Health = $Health
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_health.reset(hp)
	_health.damaged.connect(func(_a: int) -> void: _visual.call("set_damage", 1.0 - float(_health.hp) / _health.max_hp))
	_health.died.connect(_on_died)


func set_charge(on: bool) -> void:
	_visual.call("set_charge", on)


func _on_died() -> void:
	destroyed.emit()
	queue_free()
