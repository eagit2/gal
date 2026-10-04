extends Node2D
## Fire bar: a meandering chain of flickering fireballs, thin embers linking them.

const HOT := Color(1.0, 0.95, 0.6)
const FLAME := Color(1.0, 0.45, 0.1)
const EMBER := Color(0.7, 0.15, 0.1, 0.5)

var _points := PackedVector2Array()
var _grow := 0.0
var _t := 0.0


func show_chain(points: PackedVector2Array, grow: float) -> void:
	_points = points
	_grow = grow
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta


func _draw() -> void:
	var prev := Vector2.ZERO
	for i in _points.size():
		var p := _points[i]
		if _grow < float(i + 1) / _points.size():
			# Not lit yet: a faint ember shows where the bar is unfurling.
			draw_circle(p, 3.0, EMBER)
			continue
		var flicker := 1.0 + 0.2 * sin(_t * 18.0 + i * 1.7)
		draw_line(prev, p, EMBER, 3.0)
		draw_circle(p, 10.0 * flicker, Color(FLAME, 0.35))
		draw_circle(p, 7.0 * flicker, FLAME)
		draw_circle(p, 3.5, HOT)
		prev = p
