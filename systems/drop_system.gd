class_name DropSystem
extends Node
## Ships leave scrap piles (hangar currency) when they die: the enemy's scrap chance, scaled by
## difficulty and the drop_mult stat, plus a pity bonus that grows with each dry kill.

const SCRAP_SCENE := preload("res://scenes/pickups/pickup.tscn")
const MIMIC_SCENE := preload("res://scenes/enemies/mimic.tscn")
const PITY_STEP := 0.02

## Off on challenge stages.
var enabled := true
var difficulty: DifficultyDef
var player: Player
var entities: Node2D
var pity := 0.0
## The stage's chance that a pile is a Mimic.
var mimic_chance := 0.0


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.scrap_dropped.connect(func(at: Vector2, amount: int) -> void: spawn(at, amount))
	EventBus.elite_killed.connect(_on_elite_killed)


func _on_enemy_killed(node: Node2D, at: Vector2, _score: int) -> void:
	var enemy := node as Enemy
	if not enabled or enemy == null:
		return
	if GameState.rng.randf() < drop_chance(enemy.def.scrap_chance, difficulty.drop_mult, GameState.stats[&"drop_mult"], pity):
		pity = 0.0
		spawn(at, enemy.def.scrap)
	else:
		pity += PITY_STEP


## Elites burst into several piles that scatter a little.
func _on_elite_killed(def: EliteDef, at: Vector2) -> void:
	var piles := 4
	for i in piles:
		spawn(at + Vector2.from_angle(TAU * i / piles) * 22.0, ceili(def.scrap / float(piles)))


static func drop_chance(base: float, difficulty_mult: float, stat_mult: float, pity_bonus: float) -> float:
	return base * difficulty_mult * stat_mult + pity_bonus


func spawn(at: Vector2, amount: int) -> void:
	if GameState.rng.randf() < mimic_chance:
		var mimic: Node2D = MIMIC_SCENE.instantiate()
		mimic.position = at
		mimic.set("player", player)
		entities.add_child.call_deferred(mimic)
		return
	var pile: Pickup = SCRAP_SCENE.instantiate()
	pile.position = at
	pile.player = player
	pile.amount = amount
	entities.add_child.call_deferred(pile)
