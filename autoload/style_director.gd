extends CanvasLayer
## Owns the active art style. Priority: debug override > stage style > combo mode > base
## (docs/combo-styles.md: a stage-forced style keeps its art while combos still give their buff).
## Visuals listen to style_changed; a white flash covers the swap. Pixel styles can add a
## full-screen post-process (ThemeDef.post_shader).

signal style_changed(theme: ThemeDef)

const BASE_THEME := &"dusk_armada"
const THEMES := {
	&"dusk_armada": preload("res://data/themes/dusk_armada.tres"),
	&"outrun_grid": preload("res://data/themes/outrun_grid.tres"),
	&"cold_hologram": preload("res://data/themes/cold_hologram.tres"),
	&"particle_storm": preload("res://data/themes/particle_storm.tres"),
	&"pocket_four": preload("res://data/themes/pocket_four.tres"),
	&"arcade_classic": preload("res://data/themes/arcade_classic.tres"),
}
const FLASH_TIME := 0.3

var current: ThemeDef = THEMES[BASE_THEME]
var _stage_style: StringName = &""
var _combo_style: StringName = &""
var _debug_style: StringName = &""
var _post: ColorRect
var _flash: ColorRect


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_post = ColorRect.new()
	_post.material = ShaderMaterial.new()
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.visible = false
	add_child(_post)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


func set_stage_style(style: StringName) -> void:
	_stage_style = style
	_apply()


func set_combo_style(style: StringName) -> void:
	_combo_style = style
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_style"):
		var ids: Array = THEMES.keys()
		_debug_style = ids[(ids.find(current.id) + 1) % ids.size()]
		_apply()


func _apply() -> void:
	var id := BASE_THEME
	for candidate: StringName in [_combo_style, _stage_style, _debug_style]:
		if candidate in THEMES:
			id = candidate
	if id == current.id:
		return
	current = THEMES[id]
	(_post.material as ShaderMaterial).shader = current.post_shader
	_post.visible = current.post_shader != null
	_flash.color.a = 0.85
	create_tween().tween_property(_flash, "color:a", 0.0, FLASH_TIME)
	style_changed.emit(current)
