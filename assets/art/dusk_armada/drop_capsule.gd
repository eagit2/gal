extends Node2D
## Drop capsule look: a pill with an outlined rim, a slow spin glint and its letter (P, F, +1, C, !).

const SIZE := Vector2(30, 18)
const FONT_SIZE := 8

var tint := Color.WHITE
var label := ""
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := SIZE.y * 0.5
	var half := SIZE.x * 0.5 - r
	var glow := 0.75 + sin(_t * 6.0) * 0.25
	draw_circle(Vector2.ZERO, SIZE.x * 0.7, Color(tint, 0.12 * glow))
	_pill(SIZE + Vector2(4, 4), Color(0.05, 0.04, 0.1))
	_pill(SIZE, tint.darkened(0.25))
	draw_rect(Rect2(-half, -r * 0.7, half * 2.0, r * 0.5), Color(1, 1, 1, 0.35))
	var glint := fmod(_t * 0.8, 1.0) * SIZE.x - SIZE.x * 0.5
	draw_line(Vector2(glint, -r + 2), Vector2(glint - 4, r - 2), Color(1, 1, 1, 0.5), 2.0)
	var font := ThemeDB.fallback_font
	var theme := ThemeDB.get_project_theme()
	if theme and theme.default_font:
		font = theme.default_font
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
	var at := Vector2(-size.x * 0.5, FONT_SIZE * 0.5)
	draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, Color(0.05, 0.04, 0.1))
	draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)


func _pill(size: Vector2, color: Color) -> void:
	var r := size.y * 0.5
	var half := size.x * 0.5 - r
	draw_rect(Rect2(-half, -r, half * 2.0, size.y), color)
	draw_circle(Vector2(-half, 0), r, color)
	draw_circle(Vector2(half, 0), r, color)
