extends Node
## State of the current run. Reset at the start of every run.

const POOL: UpgradePool = preload("res://data/upgrades/upgrade_pool.tres")

var difficulty_id: StringName = &"pilot"
var score: int = 0
var lives: int = 3
var sector_index: int = 0
var stage_index: int = 0
var upgrades: Array[StringName] = []
## Set by the title screen's Continue; the game scene resumes the saved run and clears it.
var resume_requested := false
var owned: Array[UpgradeDef] = []
## Current run stats (see UpgradeSystem.BASE_STATS): upgrades + synergies + active combo.
var stats: Dictionary = UpgradeSystem.BASE_STATS.duplicate()
var rng := RandomNumberGenerator.new()
var _combo_effects: Array[Dictionary] = []
## Permanent bonuses (hangar, M4) in UpgradeDef effect format. Kept across runs.
var _meta_effects: Array[Dictionary] = []
var _synergies: Array[SynergyDef] = []


func start_run(difficulty: StringName, starting_lives: int) -> void:
	difficulty_id = difficulty
	score = 0
	lives = starting_lives
	sector_index = 0
	stage_index = 0
	upgrades.clear()
	owned.clear()
	_combo_effects.clear()
	_synergies.clear()
	rng.randomize()
	_recompute()
	EventBus.run_started.emit(difficulty)


## Saveable checkpoint of the run (JSON-safe). Taken at the start of each stage.
func snapshot() -> Dictionary:
	return {
		"difficulty": String(difficulty_id),
		"sector": sector_index,
		"stage": stage_index,
		"score": score,
		"lives": lives,
		"upgrades": upgrades.map(func(id: StringName) -> String: return String(id)),
	}


## Resumes a run from `snapshot()` data. Unknown upgrade ids (removed content) are skipped.
func restore(run: Dictionary) -> void:
	start_run(StringName(run.get("difficulty", "pilot")), int(run.get("lives", 3)))
	sector_index = int(run.get("sector", 0))
	stage_index = int(run.get("stage", 0))
	score = int(run.get("score", 0))
	for id: Variant in run.get("upgrades", []):
		var upgrade := POOL.find(StringName(id))
		if upgrade:
			owned.append(upgrade)
			upgrades.append(upgrade.id)
	_recompute()
	EventBus.score_changed.emit(score)


func add_score(amount: int) -> void:
	score += amount
	EventBus.score_changed.emit(score)


## Returns true when the run is over.
func lose_life() -> bool:
	lives = max(lives - 1, 0)
	EventBus.player_died.emit(lives)
	EventBus.lives_changed.emit(lives)
	return lives == 0


func gain_upgrade(upgrade: UpgradeDef) -> void:
	owned.append(upgrade)
	upgrades.append(upgrade.id)
	for effect in upgrade.effects:
		if effect["stat"] == &"lives":
			lives += int(effect["value"])
			EventBus.lives_changed.emit(lives)
	_recompute()
	EventBus.upgrade_picked.emit(upgrade.id)


func roll_choices(count: int) -> Array[UpgradeDef]:
	return UpgradeSystem.roll_choices(POOL, owned, count, rng)


func roll_drop(rarity_bonus: int) -> UpgradeDef:
	return UpgradeSystem.roll_drop(POOL, owned, rarity_bonus, rng)


## Hangar purchases call this; the effects apply under every run's upgrades.
func set_meta_effects(effects: Array[Dictionary]) -> void:
	_meta_effects = effects
	_recompute()


func set_combo_effects(effects: Array[Dictionary]) -> void:
	_combo_effects = effects
	_recompute()


func _recompute() -> void:
	stats = UpgradeSystem.compute(owned, POOL.synergies, _meta_effects + _combo_effects)
	var tags: Array[StringName] = []
	for upgrade in owned:
		tags.append_array(upgrade.tags)
	for synergy in UpgradeSystem.active_synergies(tags, POOL.synergies):
		if synergy not in _synergies:
			_synergies.append(synergy)
			EventBus.synergy_activated.emit(synergy)
	EventBus.stats_changed.emit()
