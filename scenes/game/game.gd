extends Node2D
## Game loop: plays the sector's stages in order (looping with rising aggression), handles lives,
## challenge bonuses, game over and restart. Root runs while paused (to read the pause key); Entities pause.

const PLAYER_START := Vector2(270, 860)
const RESPAWN_DELAY := 1.2
const STAGE_DELAY := 2.5
## Seconds into a stage before attacks start (they begin while later waves are still flying in).
const ATTACK_DELAY := 2.0
const BANNER_TIME := 2.0
const CHALLENGE_HIT_BONUS := 100
const CHALLENGE_PERFECT_BONUS := 10000

@export var difficulty: DifficultyDef
@export var sector: SectorDef
## Index of the first stage to play (tests start on the challenge stage).
@export var first_stage := 0

var stage_number := 0
var game_over := false
var _dev := DevOptions.from_environment()

@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _formation: Formation = $Entities/Formation
@onready var _runner: StageRunner = $Entities/StageRunner
@onready var _dives: DiveController = $Entities/DiveController
@onready var _hud: Hud = $HUD


func _ready() -> void:
	if _dev.difficulty != &"" and ResourceLoader.exists("res://data/difficulty/%s.tres" % _dev.difficulty):
		difficulty = load("res://data/difficulty/%s.tres" % _dev.difficulty)
	GameState.start_run(difficulty.id, difficulty.lives)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	_player.entities = _entities
	_player.hit.connect(_on_player_hit)
	_player.respawn(PLAYER_START)
	_runner.formation = _formation
	_runner.target = _player
	_runner.entities = _entities
	_runner.finished.connect(_on_stage_finished)
	_dives.difficulty = difficulty
	_dives.target = _player
	_player.shield.recharge_time = difficulty.shield_recharge
	_hud.set_lives(GameState.lives)
	stage_number = _dev.stage_index(sector.stages, first_stage)
	_start_stage()


func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event.is_action_pressed("fire") or (event is InputEventScreenTouch and event.pressed):
			StyleDirector.set_stage_style(&"")
			get_tree().reload_current_scene()
		elif event.is_action_pressed("pause"):
			StyleDirector.set_stage_style(&"")
			SceneRouter.go_to("res://scenes/main/title.tscn")
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		_hud.show_message("PAUSED" if get_tree().paused else "")


func current_stage() -> StageDef:
	return sector.stages[stage_number % sector.stages.size()]


func _start_stage() -> void:
	var stage := current_stage()
	var loop := stage_number / sector.stages.size()
	_dives.active = false
	_dives.aggression = 1.0 + 0.25 * loop + 0.1 * (stage_number % sector.stages.size())
	StyleDirector.set_stage_style(stage.style)
	_hud.show_banner("CHALLENGING STAGE" if stage.is_challenge else "STAGE %d" % (stage_number + 1), BANNER_TIME)
	EventBus.stage_started.emit(stage.id)
	_runner.start(stage, difficulty)
	get_tree().create_timer(ATTACK_DELAY, false).timeout.connect(_open_attacks.bind(stage_number))


func _open_attacks(for_stage: int) -> void:
	if for_stage == stage_number and not game_over:
		_dives.active = not current_stage().is_challenge


func _on_stage_finished(kills: int, total: int) -> void:
	_dives.active = false
	var stage := current_stage()
	EventBus.stage_cleared.emit(stage.id)
	if stage.is_challenge:
		var bonus := kills * CHALLENGE_HIT_BONUS
		if kills == total:
			bonus += CHALLENGE_PERFECT_BONUS
		GameState.add_score(roundi(bonus * difficulty.score_multiplier))
		_hud.show_banner("%sHITS %d / %d\nBONUS %d" % ["PERFECT!\n" if kills == total else "", kills, total, bonus], STAGE_DELAY)
	if not _dev.repeat:
		stage_number += 1
	get_tree().create_timer(STAGE_DELAY, false).timeout.connect(_on_stage_delay_done)


func _on_stage_delay_done() -> void:
	if not game_over:
		_start_stage()


func _on_enemy_killed(_enemy: Node2D, _position: Vector2, score: int) -> void:
	GameState.add_score(roundi(score * difficulty.score_multiplier))


func _on_player_hit() -> void:
	EventBus.player_hit.emit()
	var run_over := false if _dev.god else GameState.lose_life()
	_hud.set_lives(GameState.lives)
	if run_over:
		_end_run()
		return
	# Connect instead of await: the connection drops cleanly if the scene is reloaded meanwhile.
	get_tree().create_timer(RESPAWN_DELAY, false).timeout.connect(_player.respawn.bind(PLAYER_START))


func _end_run() -> void:
	game_over = true
	_dives.active = false
	EventBus.run_ended.emit(false)
	if GameState.score > SaveManager.data["high_score"]:
		SaveManager.data["high_score"] = GameState.score
		SaveManager.save()
	_hud.show_message("GAME OVER\n\nFIRE TO RETRY")
