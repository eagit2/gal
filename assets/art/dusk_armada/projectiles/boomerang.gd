extends Node2D
## A spinning crescent blade (boomerang shot visual).

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	rotation = _t * 14.0
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, 9.0, 0.3, TAU * 0.72, 14, Color(1.0, 0.85, 0.3), 5.0)
	draw_arc(Vector2.ZERO, 9.0, 0.3, TAU * 0.72, 14, Color(1.0, 1.0, 0.8), 2.0)
