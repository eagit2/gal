class_name SplitTrait
extends EnemyTrait
## Bursts into `count` fast fragments when destroyed. Counter: piercing shots, or kill it high up
## so the fragments have farther to fly.

@export var fragment: EnemyDef
@export var count := 2


func begin(enemy: Enemy) -> void:
	enemy.health().died.connect(_split.bind(enemy))


func _split(enemy: Enemy) -> void:
	# Deferred: the kill lands inside a physics callback, where areas can't be added.
	_spawn.call_deferred(enemy.global_position, enemy.difficulty, enemy.target, enemy.entities)


func _spawn(at: Vector2, difficulty: DifficultyDef, player: Player, parent: Node) -> void:
	if not is_instance_valid(parent) or not is_instance_valid(player):
		return
	for i in count:
		EnemySpawner.launch_at(fragment, difficulty, at + Vector2((i - (count - 1) / 2.0) * 24.0, 0), player, parent, 1.5)
