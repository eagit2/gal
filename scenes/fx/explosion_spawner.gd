extends Node2D
## Spawns one-shot explosion visuals where enemies die and where the player is hit.

@export var explosion_scene: PackedScene
@export var player_explosion_scene: PackedScene
@export var player: Node2D


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.wingman_lost.connect(func(at: Vector2) -> void: _spawn(player_explosion_scene, at))


func _on_enemy_killed(_enemy: Node2D, at: Vector2, _score: int) -> void:
	_spawn(explosion_scene, at)


func _on_player_hit() -> void:
	if is_instance_valid(player):
		_spawn(player_explosion_scene, player.global_position)


func _spawn(scene: PackedScene, at: Vector2) -> void:
	var fx: Node2D = scene.instantiate()
	fx.position = at
	add_child(fx)
