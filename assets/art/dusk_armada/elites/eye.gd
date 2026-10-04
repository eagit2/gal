extends Node2D
## The Scatter Titan's eye: a big open eye with a red pupil while it can be hit, a slit when shut.

const OUTLINE := Color(0.11, 0.09, 0.16)

var _open := false
var _t := 0.0


func set_open(open: bool) -> void:
	_open = open


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if _open:
		var pulse := 1.0 + 0.12 * sin(_t * 12.0)
		draw_circle(Vector2.ZERO, 15.0 * pulse, Color(1.0, 0.3, 0.2, 0.25))
		draw_circle(Vector2.ZERO, 11.0, OUTLINE)
		draw_circle(Vector2.ZERO, 9.5, Color.WHITE)
		draw_circle(Vector2.ZERO, 5.0, Color(0.9, 0.1, 0.15))
		draw_circle(Vector2(-1.5, -1.5), 1.6, Color.WHITE)
	else:
		draw_rect(Rect2(-9, -2, 18, 4), OUTLINE)
		draw_rect(Rect2(-8, -1, 16, 2), Color(0.5, 0.35, 0.1))
