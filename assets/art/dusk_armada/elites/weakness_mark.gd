extends Node2D
## A small weapon-colored badge above an elite: the gun it is weak to. Flashes on a weak hit.

const COLORS := {"laser": Color(1.0, 0.35, 0.35), "flak": Color(1.0, 0.65, 0.2), "rail": Color(0.4, 0.9, 1.0), "lance": Color(1.0, 0.95, 0.4), "missile": Color(1.0, 0.5, 0.7), "needle": Color(0.5, 1.0, 0.5), "twin": Color(0.5, 0.6, 1.0)}
const OUTLINE := Color(0.11, 0.09, 0.16)

var _weapon := ""
var _color := Color.WHITE
var _flash := 0.0


func setup(weapon: String) -> void:
	_weapon = weapon
	_color = COLORS.get(weapon, Color.from_hsv(float(hash(weapon) % 360) / 360.0, 0.6, 1.0))
	queue_redraw()


func flash() -> void:
	_flash = 0.25
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		queue_redraw()


func _draw() -> void:
	var r := 9.0 + maxf(_flash, 0.0) * 24.0
	draw_circle(Vector2.ZERO, r + 2.0, OUTLINE)
	draw_circle(Vector2.ZERO, r, Color(_color, 0.55) if _flash <= 0.0 else Color.WHITE)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, _color, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-4.5, 5.0), _weapon.left(1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
