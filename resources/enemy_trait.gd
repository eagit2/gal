class_name EnemyTrait
extends Resource
## A special behavior for a regular enemy type, on top of its brain. An enemy can carry several.
## Shared by every enemy of the type, so per-enemy state lives in `state(enemy)`, one Dictionary
## per trait per enemy.


func state(enemy: Enemy) -> Dictionary:
	return enemy.trait_state.get_or_add(self, {})


func begin(_enemy: Enemy) -> void:
	pass


## Runs every frame after movement (not while frozen).
func tick(_enemy: Enemy, _delta: float) -> void:
	pass
