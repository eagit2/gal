extends Node2D
## A soap bubble: a thin pale rim, a faint rainbow sheen and a bright highlight, wobbling as it
## floats. Used for the Bubble Blower shot and, scaled up, for an enemy trapped in one.

const RADIUS := 14.0
const RIM := Color(0.75, 0.95, 1.0, 0.9)
const FILL := Color(0.55, 0.85, 1.0, 0.16)
const SHEEN := Color(1.0, 0.6, 0.95, 0.45)

var _t := randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var wobble := Vector2(1.0 + 0.07 * sin(_t * 7.0), 1.0 - 0.07 * sin(_t * 7.0))
	draw_set_transform(Vector2.ZERO, 0.0, wobble)
	draw_circle(Vector2.ZERO, RADIUS, FILL)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, RIM, 1.6)
	draw_arc(Vector2.ZERO, RADIUS - 2.5, 0.4 + _t, 1.6 + _t, 12, SHEEN, 2.0)
	draw_arc(Vector2.ZERO, RADIUS - 2.5, PI + 0.4 - _t, PI + 1.2 - _t, 10, Color(0.6, 1.0, 0.7, 0.35), 2.0)
	draw_circle(Vector2(-RADIUS * 0.4, -RADIUS * 0.45), RADIUS * 0.18, Color(1, 1, 1, 0.85))
	draw_circle(Vector2(-RADIUS * 0.15, -RADIUS * 0.62), RADIUS * 0.08, Color(1, 1, 1, 0.7))
