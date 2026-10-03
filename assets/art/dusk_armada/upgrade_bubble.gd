extends Node2D
## Upgrade bubble look: a soft tinted sphere with a rim, a shine and the upgrade's name inside.

const RADIUS := 26.0
const FONT_SIZE := 6

var tint := Color(0.6, 0.9, 1.0)
var label := ""
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(_t * 5.0) * 0.04
	var r := RADIUS * pulse
	draw_circle(Vector2.ZERO, r, Color(tint, 0.22))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(tint, 0.95), 2.0, true)
	draw_arc(Vector2.ZERO, r - 4.0, PI * 1.1, PI * 1.45, 10, Color(1, 1, 1, 0.7), 2.0, true)
	var font := ThemeDB.fallback_font
	var theme := ThemeDB.get_project_theme()
	if theme and theme.default_font:
		font = theme.default_font
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
	draw_string_outline(font, Vector2(-size.x * 0.5, FONT_SIZE * 0.5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, Color(0.05, 0.04, 0.1))
	draw_string(font, Vector2(-size.x * 0.5, FONT_SIZE * 0.5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
