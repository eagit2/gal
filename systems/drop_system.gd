class_name DropSystem
extends Node
## What ships leave when they die, one drop per kill by priority: an item (hangar part or chip),
## else a power-up, else scrap. Rates come from the DropTable. Scrap uses the enemy's scrap chance,
## scaled by difficulty and the drop_mult stat, plus a pity bonus that grows with each dry kill.
## Items and power-ups fall as capsules; a missed capsule is gone.

const SCRAP_SCENE := preload("res://scenes/pickups/pickup.tscn")
const MIMIC_SCENE := preload("res://scenes/enemies/mimic.tscn")
const CAPSULE_SCENE := preload("res://scenes/pickups/drop_capsule.tscn")
const TABLE := Powerups.TABLE
const PITY_STEP := 0.02
enum Source { ENEMY, ELITE, BOSS }

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
	EventBus.drop_caught.connect(_on_caught)


func _on_enemy_killed(node: Node2D, at: Vector2, _score: int) -> void:
	var enemy := node as Enemy
	if not enabled or enemy == null:
		return
	if _drop_special(Source.ENEMY, at):
		return
	if GameState.rng.randf() < drop_chance(enemy.def.scrap_chance, difficulty.drop_mult, GameState.stats[&"drop_mult"], pity):
		pity = 0.0
		spawn(at, enemy.def.scrap)
	else:
		pity += PITY_STEP


## Elites burst into several piles that scatter a little, unless an item or power-up drops instead.
func _on_elite_killed(def: EliteDef, at: Vector2) -> void:
	if not enabled:
		return
	if _drop_special(Source.BOSS if is_boss(def) else Source.ELITE, at):
		return
	var piles := 4
	for i in piles:
		spawn(at + Vector2.from_angle(TAU * i / piles) * 22.0, ceili(def.scrap / float(piles)))


static func is_boss(def: EliteDef) -> bool:
	return def is BossDef or not def.phases.is_empty()


static func drop_chance(base: float, difficulty_mult: float, stat_mult: float, pity_bonus: float) -> float:
	return base * difficulty_mult * stat_mult + pity_bonus


## Which drop a kill makes from two rolls in 0..1: &"item", &"powerup" or &"" (scrap as usual).
static func pick(source: Source, table: DropTable, item_roll: float, powerup_roll: float) -> StringName:
	var item: float = [table.enemy_item, table.elite_item, table.boss_item][source]
	var powerup: float = [table.enemy_powerup, table.elite_powerup, table.boss_powerup][source]
	if item_roll < item:
		return &"item"
	if powerup_roll < powerup:
		return &"powerup"
	return &""


## {"kind": &"part"|&"chip", "id"} for an item from `source`, or {} when its pool is empty.
static func pick_item(source: Source, table: DropTable, catalog: HangarCatalog, rng: RandomNumberGenerator) -> Dictionary:
	if source == Source.ELITE and not table.elite_chips.is_empty() and rng.randf() < table.elite_chip_share:
		return {"kind": &"chip", "id": table.elite_chips[rng.randi() % table.elite_chips.size()]}
	var tiers: Array[int] = [table.enemy_tiers, table.elite_tiers, table.boss_tiers][source]
	var pool := catalog.parts.filter(func(p: PartDef) -> bool: return not p.unique and int(p.tier) in tiers)
	if pool.is_empty():
		return {}
	return {"kind": &"part", "id": (pool[rng.randi() % pool.size()] as PartDef).id}


## Drops an item or power-up capsule when the rolls say so. Returns true when one dropped.
func _drop_special(source: Source, at: Vector2) -> bool:
	var rng := GameState.rng
	var what := pick(source, TABLE, rng.randf(), rng.randf())
	if what == &"item":
		var item := pick_item(source, TABLE, Hangar.CATALOG, rng)
		if not item.is_empty():
			_spawn_capsule(at, item["kind"], item["id"])
			return true
		what = &"powerup" if rng.randf() < [TABLE.enemy_powerup, TABLE.elite_powerup, TABLE.boss_powerup][source] else &""
	if what == &"powerup":
		_spawn_capsule(at, &"powerup", Powerups.KINDS[rng.randi() % Powerups.KINDS.size()])
		return true
	return false


## A capsule was caught: power-ups apply to this life (capped ones pay scrap), items bank to the save.
func _on_caught(kind: StringName, id: StringName, at: Vector2) -> void:
	match kind:
		&"powerup":
			if GameState.add_powerup(id):
				EventBus.drop_banked.emit(Powerups.NAMES[id], Powerups.COLORS[id])
			else:
				Hangar.add_scrap(TABLE.capped_scrap, at)
				EventBus.drop_banked.emit("%s MAXED\n+SCRAP" % Powerups.NAMES[id], Powerups.COLORS[id])
		&"chip":
			var chip := Hangar.CATALOG.chip(id)
			Hangar.bank_chip(id)
			EventBus.drop_banked.emit("CHIP FOUND\n%s" % chip.display_name.to_upper(), chip.color)
		&"part":
			var part := Hangar.CATALOG.part(id)
			if Hangar.bank_part(id, TABLE.owned_part_scrap):
				EventBus.drop_banked.emit("PART FOUND\n%s" % part.display_name.to_upper(), Color(1, 0.8, 0.35))
			else:
				EventBus.drop_banked.emit("%s\nOWNED: +SCRAP" % part.display_name.to_upper(), Color(1, 0.8, 0.35))


func _spawn_capsule(at: Vector2, kind: StringName, id: StringName) -> void:
	var capsule: DropCapsule = CAPSULE_SCENE.instantiate()
	capsule.position = at
	capsule.player = player
	capsule.setup(kind, id)
	entities.add_child.call_deferred(capsule)


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
