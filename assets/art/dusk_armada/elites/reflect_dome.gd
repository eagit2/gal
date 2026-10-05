extends Node2D
## Aegis's dome: a closed ring (or one with an open arc). Flickers before it overloads and fades to a
## faint outline while down.

const BLUE := Color(0.55, 0.85, 1.0)
const OUTLINE := Color(0.11, 0.09, 0.16)

var _radius := 60.0
var _gap_angle := 0.0
var _gap_arc := 1.0
var _dropped := false
var _warn := false
var _t := 0.0


func set_dome(radius: float, gap_angle: float, gap_arc: float, dropped: bool, warn: bool) -> void:
	_radius = radius
	_gap_angle = gap_angle
	_gap_arc = gap_arc
	_dropped = dropped
	_warn = warn


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if _dropped:
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 40, Color(BLUE, 0.15 + 0.1 * sin(_t * 12.0)), 2.0)
		return
	var from := _gap_angle + _gap_arc / 2.0
	var to := _gap_angle - _gap_arc / 2.0 + TAU
	var glow := 0.7 + (0.3 * sin(_t * 30.0) if _warn else 0.0)
	draw_arc(Vector2.ZERO, _radius, from, to, 48, OUTLINE, 9.0)
	draw_arc(Vector2.ZERO, _radius, from, to, 48, Color(BLUE, glow), 5.0)
	if _gap_arc <= 0.0:
		return
	for edge in [from, to]:
		draw_circle(Vector2.from_angle(edge) * _radius, 5.0, Color.WHITE)
