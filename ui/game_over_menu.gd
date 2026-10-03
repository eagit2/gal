class_name GameOverMenu
extends MenuPanel
## Shown when the last ship is lost: Restart level, Hangar, Load, Options, Quit (Quit then picks
## the main menu or leaving the game).

const TITLE_SCENE := "res://scenes/main/title.tscn"
const HANGAR_SCENE := "res://scenes/main/hangar.tscn"

signal restart_requested()


func _ready() -> void:
	_show_main()


func _show_main() -> void:
	clear()
	add_label("GAME OVER", 32)
	add_label("SCORE %d   +%d SCRAP" % [GameState.score, Hangar.run_earned], 14)
	add_button("RESTART LEVEL", restart_requested.emit)
	add_button("HANGAR", _go.bind(HANGAR_SCENE))
	add_button("LOAD", _open_load)
	add_button("OPTIONS", func() -> void: open(OptionsPanel.new()))
	add_button("QUIT", _show_quit)
	focus_first()


func _show_quit() -> void:
	clear()
	add_label("QUIT", 20)
	add_button("MAIN MENU", _go.bind(TITLE_SCENE))
	add_button("QUIT GAME", _quit_game)
	add_button("BACK", _show_main)
	focus_first()


func _open_load() -> void:
	var picker := SlotPicker.new()
	picker.picked.connect(SlotPicker.play_slot)
	open(picker)


func _go(scene: String) -> void:
	StyleDirector.set_stage_style(&"")
	SceneRouter.go_to(scene)


## Browsers only let a page close tabs it opened, so on web this falls back to the title screen.
func _quit_game() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.close()")
		_go(TITLE_SCENE)
	else:
		get_tree().quit()


func _on_cancel() -> void:
	_show_main()
