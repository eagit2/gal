extends Node2D
## Spawns a one-shot explosion visual wherever an enemy dies.

@export var explosion_scene: PackedScene


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _on_enemy_killed(_enemy: Node2D, at: Vector2, _score: int) -> void:
	var fx: Node2D = explosion_scene.instantiate()
	fx.position = at
	add_child(fx)
