extends Node2D
## One of the Leaf Warden's leaves. Green while it guards, reddens and shakes when it is about to launch.

const OUTLINE := Color(0.11, 0.09, 0.16)
var _points := PackedVector2Array([Vector2(0, -12), Vector2(7, -3), Vector2(5, 8), Vector2(0, 12), Vector2(-5, 8), Vector2(-7, -3), Vector2(0, -12)])

var _warn := false
var _t := 0.0


func set_warn(on: bool) -> void:
	_warn = on


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var fill := Color(0.35, 0.8, 0.3)
	if _warn:
		fill = Color(1.0, 0.35, 0.25) if fmod(_t, 0.14) < 0.07 else Color(1.0, 0.8, 0.3)
	draw_colored_polygon(_points.slice(0, 6), fill)
	draw_polyline(_points, OUTLINE, 2.0)
	draw_line(Vector2(0, -9), Vector2(0, 9), Color(OUTLINE, 0.6), 1.5)
