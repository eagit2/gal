extends Node2D
## Orbit Warden drone: a steel hexagon with a glowing eye; the eye dims as it takes damage.

const STEEL := Color(0.6, 0.72, 0.85)
const OUTLINE := Color(0.11, 0.09, 0.16)

var _fraction := 1.0


func set_fraction(fraction: float) -> void:
	_fraction = fraction
	queue_redraw()


func _draw() -> void:
	var points := PackedVector2Array()
	for i in 6:
		points.append(Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * 13.0)
	draw_colored_polygon(points, STEEL)
	points.append(points[0])
	draw_polyline(points, OUTLINE, 2.5)
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.55, 0.3, 0.35 + 0.65 * _fraction))
