class_name RockDropTrait
extends EnemyTrait
## Drops a rock once per dive, after it passes `drop_y`. The rock crushes any enemy it falls on and
## costs a life on contact. Counter: dodge it, and lure other enemies under it.

@export var rock_scene: PackedScene = preload("res://scenes/enemies/elites/rock_chunk.tscn")
@export var drop_y := 300.0


func tick(enemy: Enemy, _delta: float) -> void:
	if enemy.state != Enemy.State.DIVING:
		state(enemy)["dropped"] = false
		return
	if state(enemy).get("dropped", false) or enemy.position.y < drop_y:
		return
	state(enemy)["dropped"] = true
	var rock: Node2D = rock_scene.instantiate()
	rock.position = enemy.position + Vector2(0, 18)
	rock.set("source", enemy)
	enemy.entities.add_child.call_deferred(rock)
