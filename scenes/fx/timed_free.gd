extends Node2D
## Frees this node after `lifetime` seconds (one-shot effects).

@export var lifetime := 0.4


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
