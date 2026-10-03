class_name EnemyTrait
extends Resource
## A special behavior for a regular enemy type, on top of its brain. Shared by every enemy of the
## type, so per-enemy state lives in `enemy.trait_state`.


func begin(_enemy: Enemy) -> void:
	pass


## Runs every frame after movement (not while frozen).
func tick(_enemy: Enemy, _delta: float) -> void:
	pass
