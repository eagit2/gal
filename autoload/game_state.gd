extends Node
## State of the current run. Reset at the start of every run.

var difficulty_id: StringName = &"pilot"
var score: int = 0
var lives: int = 3
var sector_index: int = 0
var stage_index: int = 0
var upgrades: Array[StringName] = []


func start_run(difficulty: StringName, starting_lives: int) -> void:
	difficulty_id = difficulty
	score = 0
	lives = starting_lives
	sector_index = 0
	stage_index = 0
	upgrades.clear()
	EventBus.run_started.emit(difficulty)


func add_score(amount: int) -> void:
	score += amount
	EventBus.score_changed.emit(score)


## Returns true when the run is over.
func lose_life() -> bool:
	lives = max(lives - 1, 0)
	EventBus.player_died.emit(lives)
	return lives == 0
