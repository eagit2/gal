class_name RockChunk
extends Node2D
## A chunk broken off a towed rock: tumbles down, costs a life on contact, and leaves scrap when shot.

const BOTTOM := 1000.0

var _velocity := Vector2(randf_range(-60.0, 60.0), randf_range(120.0, 190.0))
var _spin := randf_range(-3.0, 3.0)


func _ready() -> void:
	$Health.died.connect(_on_died)
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: queue_free())


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	position += _velocity * delta
	rotation += _spin * delta
	if position.y > BOTTOM:
		queue_free()


func _on_died() -> void:
	EventBus.scrap_dropped.emit(global_position, 2)
	queue_free()
