extends Control
## Title screen: Continue (resumes the saved run at the start of its last stage), New Game (with a
## difficulty pick, and a confirm when it would overwrite a save). Any click or key also unlocks
## browser audio. Menu items are built in code: add a screen with one `_add_item` line.

const GAME_SCENE := "res://scenes/game/game.tscn"
const DIFFICULTY_DIR := "res://data/difficulty"

## Title music. Left empty until audio lands; set it in title.tscn.
@export var music: AudioStream

var _difficulties: Array[DifficultyDef] = []
var _difficulty_index := 0
var _continue: Button
var _new_game: Button
var _difficulty_button: Button
var _difficulty_info := Label.new()

@onready var _menu: VBoxContainer = $Menu
@onready var _confirm: PanelContainer = $Confirm


func _ready() -> void:
	if music:
		AudioManager.play_music(music)
	$HighScore.text = "HIGH SCORE  %d" % SaveManager.data["high_score"]
	_difficulties = load_difficulties()
	_difficulty_index = maxi(_find_difficulty(StringName(SaveManager.data["last_difficulty"])), 0)
	_continue = _add_item("CONTINUE", _on_continue)
	_new_game = _add_item("NEW GAME", _on_new_game)
	_difficulty_button = _add_item("", _cycle_difficulty.bind(1))
	_difficulty_button.gui_input.connect(_on_difficulty_input)
	_difficulty_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_info.add_theme_font_size_override(&"font_size", 16)
	_menu.add_child(_difficulty_info)
	# M4: _add_item("HANGAR", SceneRouter.go_to.bind("res://scenes/main/hangar.tscn"))
	_refresh()
	$Confirm/Box/Buttons/Yes.pressed.connect(_start_new)
	$Confirm/Box/Buttons/No.pressed.connect(_close_confirm)
	_confirm.visible = false
	(_new_game if _continue.disabled else _continue).grab_focus()


## Every DifficultyDef in data/difficulty, easiest first (by score multiplier).
static func load_difficulties() -> Array[DifficultyDef]:
	var list: Array[DifficultyDef] = []
	for file in ResourceLoader.list_directory(DIFFICULTY_DIR):
		var def := load(DIFFICULTY_DIR.path_join(file)) as DifficultyDef
		if def:
			list.append(def)
	list.sort_custom(func(a: DifficultyDef, b: DifficultyDef) -> bool: return a.score_multiplier < b.score_multiplier)
	return list


func _unhandled_input(event: InputEvent) -> void:
	if _confirm.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_confirm()


func _add_item(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.pressed.connect(action)
	_menu.add_child(button)
	return button


func _refresh() -> void:
	var run: Dictionary = SaveManager.data["run"]
	_continue.disabled = run.is_empty()
	_continue.text = "CONTINUE"
	if not run.is_empty():
		var i := _find_difficulty(StringName(run.get("difficulty", "")))
		var name := _difficulties[i].display_name.to_upper() if i >= 0 else ""
		_continue.text = "CONTINUE  STAGE %d %s" % [int(run.get("stage", 0)) + 1, name]
	var def := _difficulties[_difficulty_index]
	_difficulty_button.text = "<   %s   >" % def.display_name.to_upper()
	_difficulty_info.text = "%d LIVES   SCORE x%s" % [def.lives, str(def.score_multiplier)]


func _find_difficulty(id: StringName) -> int:
	for i in _difficulties.size():
		if _difficulties[i].id == id:
			return i
	return -1


func _cycle_difficulty(step: int) -> void:
	_difficulty_index = wrapi(_difficulty_index + step, 0, _difficulties.size())
	_refresh()


func _on_difficulty_input(event: InputEvent) -> void:
	for pair: Array in [["ui_left", -1], ["ui_right", 1]]:
		if event.is_action_pressed(pair[0]):
			_difficulty_button.accept_event()
			_cycle_difficulty(pair[1])


func _on_continue() -> void:
	GameState.resume_requested = true
	SceneRouter.go_to(GAME_SCENE)


func _on_new_game() -> void:
	if SaveManager.has_run():
		_menu.visible = false
		_confirm.visible = true
		$Confirm/Box/Buttons/No.grab_focus()
	else:
		_start_new()


func _close_confirm() -> void:
	_confirm.visible = false
	_menu.visible = true
	_new_game.grab_focus()


func _start_new() -> void:
	var def := _difficulties[_difficulty_index]
	SaveManager.data["last_difficulty"] = String(def.id)
	SaveManager.clear_run()
	GameState.resume_requested = false
	GameState.difficulty_id = def.id
	SceneRouter.go_to(GAME_SCENE)
