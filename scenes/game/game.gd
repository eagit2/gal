extends Node2D
## M1 game loop: waves of formation enemies, score, lives, game over and restart.
## Root runs while paused (to read the pause key); Entities pause.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const PLAYER_START := Vector2(270, 860)
const GRID_ORIGIN := Vector2(81, 130)
const GRID_STEP := Vector2(54, 52)
const GRID_SIZE := Vector2i(8, 4)
const RESPAWN_DELAY := 1.2
const WAVE_DELAY := 1.5

@export var difficulty: DifficultyDef
@export var enemy_def: EnemyDef

var wave := 0
var game_over := false

@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _hud: Hud = $HUD


func _ready() -> void:
	GameState.start_run(difficulty.id, difficulty.lives)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	_player.entities = _entities
	_player.hit.connect(_on_player_hit)
	_player.respawn(PLAYER_START)
	_hud.set_lives(GameState.lives)
	spawn_wave()


func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event.is_action_pressed("fire") or (event is InputEventScreenTouch and event.pressed):
			get_tree().reload_current_scene()
		elif event.is_action_pressed("pause"):
			SceneRouter.go_to("res://scenes/main/title.tscn")
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		_hud.show_message("PAUSED" if get_tree().paused else "")


func spawn_wave() -> void:
	EventBus.stage_started.emit(StringName("wave_%d" % wave))
	for row in GRID_SIZE.y:
		for col in GRID_SIZE.x:
			var enemy: Enemy = ENEMY_SCENE.instantiate()
			enemy.setup(enemy_def, GRID_ORIGIN + Vector2(col, row) * GRID_STEP, difficulty)
			enemy.target = _player
			enemy.entities = _entities
			enemy.aggression = 1.0 + 0.2 * wave
			_entities.add_child(enemy)


func _on_enemy_killed(_enemy: Node2D, _position: Vector2, score: int) -> void:
	GameState.add_score(roundi(score * difficulty.score_multiplier))
	if get_tree().get_nodes_in_group(&"enemies").is_empty():
		EventBus.stage_cleared.emit(StringName("wave_%d" % wave))
		wave += 1
		# Connect instead of await: the connection drops cleanly if the scene is reloaded meanwhile.
		get_tree().create_timer(WAVE_DELAY, false).timeout.connect(_on_wave_delay_done)


func _on_wave_delay_done() -> void:
	if not game_over:
		spawn_wave()


func _on_player_hit() -> void:
	EventBus.player_hit.emit()
	var run_over := GameState.lose_life()
	_hud.set_lives(GameState.lives)
	if run_over:
		_end_run()
		return
	get_tree().create_timer(RESPAWN_DELAY, false).timeout.connect(_player.respawn.bind(PLAYER_START))


func _end_run() -> void:
	game_over = true
	EventBus.run_ended.emit(false)
	if GameState.score > SaveManager.data["high_score"]:
		SaveManager.data["high_score"] = GameState.score
		SaveManager.save()
	_hud.show_message("GAME OVER\n\nFIRE TO RETRY")
