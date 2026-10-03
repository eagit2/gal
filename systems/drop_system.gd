class_name DropSystem
extends Node
## Ships leave scrap piles (hangar currency) when they die: the enemy's scrap chance, scaled by
## difficulty and the drop_mult stat, plus a pity bonus that grows with each dry kill.

const SCRAP_SCENE := preload("res://scenes/pickups/pickup.tscn")
const PITY_STEP := 0.02

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
	if GameState.rng.randf() < drop_chance(enemy.def.scrap_chance, difficulty.drop_mult, GameState.stats[&"drop_mult"], pity):
		pity = 0.0
		spawn(at, enemy.def.scrap)
	else:
		pity += PITY_STEP


static func drop_chance(base: float, difficulty_mult: float, stat_mult: float, pity_bonus: float) -> float:
	return base * difficulty_mult * stat_mult + pity_bonus


func spawn(at: Vector2, amount: int) -> void:
	var pile: Pickup = SCRAP_SCENE.instantiate()
	pile.position = at
	pile.player = player
	pile.amount = amount
	entities.add_child.call_deferred(pile)
