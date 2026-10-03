extends Node
## State of the current run. Reset at the start of every run.

var difficulty_id: StringName = &"pilot"
var score: int = 0
var lives: int = 3
var sector_index: int = 0
var stage_index: int = 0
## Set by the title screen's Continue; the game scene resumes the saved run and clears it.
var resume_requested := false
## Current run stats (see UpgradeSystem.BASE_STATS): hangar loadout + active combo.
var stats: Dictionary = UpgradeSystem.BASE_STATS.duplicate()
var rng := RandomNumberGenerator.new()
## Seconds left on a Cryo Pulse freeze. Enemies, enemy shots and attack orders hold while above 0.
var freeze_left := 0.0
var _combo_effects: Array[Dictionary] = []
## Permanent bonuses from the hangar loadout. Kept across runs.
var _meta_effects: Array[Dictionary] = []


func start_run(difficulty: StringName, starting_lives: int) -> void:
	difficulty_id = difficulty
	score = 0
	lives = starting_lives
	sector_index = 0
	stage_index = 0
	freeze_left = 0.0
	_combo_effects.clear()
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
	}


## Resumes a run from `snapshot()` data.
func restore(run: Dictionary) -> void:
	start_run(StringName(run.get("difficulty", "pilot")), int(run.get("lives", 3)))
	sector_index = int(run.get("sector", 0))
	stage_index = int(run.get("stage", 0))
	score = int(run.get("score", 0))
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


## The hangar loadout calls this; the effects apply to every run.
func set_meta_effects(effects: Array[Dictionary]) -> void:
	_meta_effects = effects
	_recompute()


func set_combo_effects(effects: Array[Dictionary]) -> void:
	_combo_effects = effects
	_recompute()


func _recompute() -> void:
	stats = UpgradeSystem.compute(_meta_effects + _combo_effects)
	EventBus.stats_changed.emit()
