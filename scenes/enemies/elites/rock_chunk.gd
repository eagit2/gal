class_name RockChunk
extends Node2D
## A falling rock chunk (broken off a towed rock, or dropped by a Rock Dropper): tumbles down,
## crushes enemies in its way, costs a life on contact, and leaves scrap when shot.

const BOTTOM := 1000.0

var velocity := Vector2(randf_range(-60.0, 60.0), randf_range(120.0, 190.0))
var _spin := randf_range(-3.0, 3.0)
## Whatever dropped it, so the Crusher spares it.
var source: Node


func _ready() -> void:
	$Crusher.ignore = source
	$Health.died.connect(_on_died)
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: queue_free())


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	position += velocity * delta
	rotation += _spin * delta
	if position.y > BOTTOM:
		queue_free()


func _on_died() -> void:
	EventBus.scrap_dropped.emit(global_position, 2)
	queue_free()
