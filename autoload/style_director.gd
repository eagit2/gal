extends CanvasLayer
## Owns the active art style. Priority: debug override > combo (M3) > stage style > base.
## Visuals listen to style_changed; a white flash covers the swap.

signal style_changed(theme: ThemeDef)

const BASE_THEME := &"dusk_armada"
const THEMES := {
	&"dusk_armada": preload("res://data/themes/dusk_armada.tres"),
	&"outrun_grid": preload("res://data/themes/outrun_grid.tres"),
}
const FLASH_TIME := 0.3

var current: ThemeDef = THEMES[BASE_THEME]
var _stage_style: StringName = &""
var _debug_style: StringName = &""
var _flash: ColorRect


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


func set_stage_style(style: StringName) -> void:
	_stage_style = style
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_style"):
		var ids: Array = THEMES.keys()
		_debug_style = ids[(ids.find(current.id) + 1) % ids.size()]
		_apply()


func _apply() -> void:
	var id := BASE_THEME
	if _stage_style in THEMES:
		id = _stage_style
	if _debug_style in THEMES:
		id = _debug_style
	if id == current.id:
		return
	current = THEMES[id]
	_flash.color.a = 0.85
	create_tween().tween_property(_flash, "color:a", 0.0, FLASH_TIME)
	style_changed.emit(current)
