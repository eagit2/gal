class_name MineTrait
extends EnemyTrait
## Lays up to `max_mines` slow drifting mines per dive. A mine costs a life on contact, but a shot
## sets it off and the blast wrecks nearby enemies. Counter: shoot mines next to enemy clusters.

@export var mine_scene: PackedScene
@export var interval := 0.8
@export var max_mines := 3


func tick(enemy: Enemy, delta: float) -> void:
	if enemy.state != Enemy.State.DIVING:
		enemy.trait_state["laid"] = 0
		enemy.trait_state["t"] = 0.0
		return
	var t: float = enemy.trait_state.get("t", 0.0) + delta
	var laid: int = enemy.trait_state.get("laid", 0)
	if t >= interval and laid < max_mines and enemy.position.y > 160.0 and enemy.position.y < 720.0:
		t = 0.0
		enemy.trait_state["laid"] = laid + 1
		var mine: Node2D = mine_scene.instantiate()
		mine.position = enemy.position
		enemy.entities.add_child.call_deferred(mine)
	enemy.trait_state["t"] = t
