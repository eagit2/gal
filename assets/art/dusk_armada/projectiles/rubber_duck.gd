extends Node2D
## A little yellow rubber duck with an orange beak, seen from the side. It faces the way it is
## heading (left or right), bobs a little, and squashes flat for a moment when it squeaks.

const BODY := Color(1.0, 0.86, 0.2)
const SHADE := Color(0.92, 0.66, 0.1)
const BEAK := Color(1.0, 0.5, 0.12)
const OUTLINE := Color(0.25, 0.15, 0.05)
const SQUEAK_TIME := 0.18

var _t := 0.0
var _squeak := 0.0
var _facing := 1.0


func squeak() -> void:
	_squeak = SQUEAK_TIME


func heading(velocity: Vector2) -> void:
	if absf(velocity.x) > 1.0:
		_facing = signf(velocity.x)


func _process(delta: float) -> void:
	_t += delta
	_squeak = maxf(0.0, _squeak - delta)
	var squash := _squeak / SQUEAK_TIME
	scale = Vector2(_facing * (1.0 + 0.35 * squash), 1.0 - 0.35 * squash)
	rotation = sin(_t * 9.0) * 0.18
	queue_redraw()


func _draw() -> void:
	# Body: a fat oval with a tail tip at the back (left; the duck faces +x).
	draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.0, 0.72))
	draw_circle(Vector2.ZERO, 11.5, OUTLINE)
	draw_circle(Vector2.ZERO, 10.0, BODY)
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(-15, -5), Vector2(-11, 4)]), BODY)
	draw_arc(Vector2(-1, 4), 5.0, 0.3, 2.6, 8, SHADE, 2.0)  # wing
	# Head, eye and beak.
	draw_circle(Vector2(5, -6), 7.0, OUTLINE)
	draw_circle(Vector2(5, -6), 5.8, BODY)
	draw_circle(Vector2(7, -8), 1.6, OUTLINE)
	draw_circle(Vector2(7.4, -8.5), 0.6, Color.WHITE)
	var open := 2.5 if _squeak > 0.0 else 0.6
	draw_colored_polygon(PackedVector2Array([Vector2(10, -7), Vector2(16, -6), Vector2(10, -5 + open)]), BEAK)
	if _squeak > 0.0:
		for i in 3:
			var d := Vector2.from_angle(-0.6 + 0.4 * i)
			draw_line(Vector2(17, -6) + d * 3.0, Vector2(17, -6) + d * 7.0, Color(1, 1, 1, 0.9), 1.5)
