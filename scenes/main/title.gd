extends Control
## Title screen: Continue (pick a save slot and resume it), New Game (difficulty pick, then a save
## slot; overwriting a used slot asks to confirm), Hangar and Options. Any click or key also unlocks
## browser audio (title music comes from SoundBank.scene_music). Menu items are built in code: add a screen with one `_add_item` line.

const GAME_SCENE := "res://scenes/game/game.tscn"
const DIFFICULTY_DIR := "res://data/difficulty"

var _difficulties: Array[DifficultyDef] = []
var _difficulty_index := 0
var _continue: Button
var _new_game: Button
var _difficulty_button: Button
var _difficulty_info := Label.new()

@onready var _menu: VBoxContainer = $Menu


func _ready() -> void:
	$Version.text = "V%s" % ProjectSettings.get_setting("application/config/version", "0")
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
	_add_item("HANGAR   %d SCRAP" % Hangar.credits(), SceneRouter.go_to.bind("res://scenes/main/hangar.tscn"))
	_add_item("OPTIONS", func() -> void: _open(OptionsPanel.new()))
	_refresh()
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


func _add_item(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.pressed.connect(action)
	_menu.add_child(button)
	return button


func _refresh() -> void:
	var used := range(SaveManager.SLOT_COUNT).filter(SaveManager.slot_exists)
	_continue.disabled = used.is_empty()
	var def := _difficulties[_difficulty_index]
	_difficulty_button.text = "<   %s   >" % def.display_name.to_upper()
	_difficulty_info.text = "%d SHIP%s   SCORE x%s" % [def.lives, "" if def.lives == 1 else "S", str(def.score_multiplier)]


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
	var picker := SlotPicker.new()
	picker.picked.connect(SlotPicker.play_slot)
	_open(picker)


func _on_new_game() -> void:
	var picker := SlotPicker.new(true)
	picker.picked.connect(_start_new)
	_open(picker)


func _open(panel: MenuPanel) -> void:
	_menu.visible = false
	add_child(panel)
	panel.closed.connect(func() -> void:
		panel.queue_free()
		_menu.visible = true
		_refresh()
		(_new_game if _continue.disabled else _continue).grab_focus())


func _start_new(slot: int) -> void:
	var def := _difficulties[_difficulty_index]
	SaveManager.new_game(slot, def.id)
	GameState.resume_requested = false
	GameState.difficulty_id = def.id
	SceneRouter.go_to(GAME_SCENE)
