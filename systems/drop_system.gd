class_name DropSystem
extends Node
## Rolls an upgrade drop on every kill: the enemy's drop chance, scaled by difficulty and the Lucky
## Charm stat, plus a pity bonus that grows with each dry kill and resets on a drop. Some drops are
## gold utility capsules (freeze, shield, credits); the rest change bullets.

const PICKUP_SCENE := preload("res://scenes/pickups/pickup.tscn")
const PITY_STEP := 0.0025
## Share of drops that are utility capsules.
const UTILITY_SHARE := 0.25

## Off on challenge stages.
var enabled := true
var difficulty: DifficultyDef
var player: Player
var entities: Node2D
var pity := 0.0


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _on_enemy_killed(node: Node2D, at: Vector2, _score: int) -> void:
	var enemy := node as Enemy
	if not enabled or enemy == null:
		return
	if GameState.rng.randf() < drop_chance(enemy.def.drop_chance, difficulty.drop_mult, GameState.stats[&"drop_mult"], pity):
		pity = 0.0
		spawn(at, enemy.def.drop_rarity_bonus, GameState.rng.randf() < UTILITY_SHARE)
	else:
		pity += PITY_STEP


static func drop_chance(base: float, difficulty_mult: float, stat_mult: float, pity_bonus: float) -> float:
	return base * difficulty_mult * stat_mult + pity_bonus


func spawn(at: Vector2, rarity_bonus: int, utility := false) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.position = at
	pickup.player = player
	pickup.rarity_bonus = rarity_bonus
	pickup.utility = utility
	entities.add_child.call_deferred(pickup)
