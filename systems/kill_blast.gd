class_name KillBlast
extends Node
## While the explode_radius stat is above 0 (Chain Reaction mode, Detonator synergy), every kill
## bursts and deals 1 damage to enemies within that radius. Blasts resolve a frame later, so a dense
## formation goes up in a visible cascade.

const DAMAGE := 1


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _on_enemy_killed(_enemy: Node2D, at: Vector2, _score: int) -> void:
	var radius: float = GameState.stats[&"explode_radius"]
	if radius > 0.0:
		_blast.call_deferred(at, radius)


func _blast(at: Vector2, radius: float) -> void:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.global_position.distance_squared_to(at) <= radius * radius:
			enemy.damage(DAMAGE)
