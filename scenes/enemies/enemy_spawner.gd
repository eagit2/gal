class_name EnemySpawner
extends RefCounted
## Spawns an enemy that attacks at once from `at`, with no formation slot (hive swarms, split
## fragments). It is freed when its attack ends.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")


static func launch_at(def: EnemyDef, difficulty: DifficultyDef, at: Vector2, player: Player, parent: Node, aggression := 1.3) -> Enemy:
	var start := Curve2D.new()
	start.add_point(at)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(def, difficulty, start, Enemy.NO_SLOT, null)
	enemy.target = player
	enemy.entities = parent
	parent.add_child(enemy)
	enemy.launch(player, aggression, def.brain)
	return enemy
