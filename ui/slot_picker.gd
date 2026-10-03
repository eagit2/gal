class_name SlotPicker
extends MenuPanel
## Picks one of SaveManager's save slots. Load mode only enables used slots; new-game mode
## (`overwrite`) asks for a second confirmation before replacing a used slot.

const GAME_SCENE := "res://scenes/game/game.tscn"

signal picked(slot: int)

var overwrite := false
var _confirming := false


func _init(new_game := false) -> void:
	super()
	overwrite = new_game


func _ready() -> void:
	_show_slots()


## Loads `slot` and plays it: resumes its saved stage, or starts a run on its last difficulty.
static func play_slot(slot: int) -> void:
	SaveManager.load_slot(slot)
	GameState.resume_requested = SaveManager.has_run()
	GameState.difficulty_id = StringName(SaveManager.data["last_difficulty"])
	StyleDirector.set_stage_style(&"")
	SceneRouter.go_to(GAME_SCENE)


static func describe(slot: int, info: Dictionary) -> String:
	if info.is_empty():
		return "SLOT %d\nEMPTY" % (slot + 1)
	var run: Dictionary = info.get("run", {})
	var where := "STAGE %d" % (int(run.get("stage", 0)) + 1) if not run.is_empty() else "HANGAR"
	return "SLOT %d  %s\n%d SCRAP" % [slot + 1, where, int(info.get("currency", 0))]


func _show_slots() -> void:
	_confirming = false
	clear()
	add_label("CHOOSE A SLOT" if overwrite else "LOAD GAME", 20)
	for i in SaveManager.SLOT_COUNT:
		var info := SaveManager.slot_info(i)
		var button := add_button(describe(i, info), _choose.bind(i), info.is_empty() and not overwrite)
		button.custom_minimum_size.y = 80
	add_button("BACK", _on_cancel)
	focus_first()


func _choose(slot: int) -> void:
	if not overwrite or SaveManager.slot_info(slot).is_empty():
		picked.emit(slot)
		return
	_confirming = true
	clear()
	add_label("OVERWRITE SLOT %d?\n\nITS PROGRESS\nWILL BE LOST." % (slot + 1), 16)
	add_button("YES, OVERWRITE", picked.emit.bind(slot))
	add_button("NO", _show_slots).grab_focus()


func _on_cancel() -> void:
	if _confirming:
		_show_slots()
	else:
		closed.emit()
