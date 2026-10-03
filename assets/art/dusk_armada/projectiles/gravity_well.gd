extends Node2D
## Gravity Gun well: a black-hole look with no outline ring, a dark core with a violet glow and
## curved arms of light swirling into it. While it pulls it swells and faint dust streaks spiral in
## from the edge of its reach.

const CORE := Color(0.02, 0.0, 0.05)
const GLOW := Color(0.55, 0.3, 1.0)
const SWIRL := Color(0.8, 0.6, 1.0)
const RADIUS := 8.0
const PULL_SCALE := 1.8

var _pulling := false
var _reach := 150.0
var _t := 0.0
var _size := 1.0


func set_pulling(on: bool, reach: float) -> void:
	_pulling = on
	_reach = reach


func _process(delta: float) -> void:
	_t += delta
	_size = move_toward(_size, PULL_SCALE if _pulling else 1.0, delta * 4.0)
	queue_redraw()


func _draw() -> void:
	var r := RADIUS * _size
	draw_circle(Vector2.ZERO, r * 2.2, Color(GLOW, 0.12))
	draw_circle(Vector2.ZERO, r * 1.5, Color(GLOW, 0.22))
	# Swirling arms falling into the core.
	for arm in 3:
		var points := PackedVector2Array()
		for i in 13:
			var f := i / 12.0
			var angle := _t * 5.0 + arm * TAU / 3.0 + f * 2.4
			points.append(Vector2.from_angle(angle) * lerpf(r * 2.1, r * 0.9, f))
		draw_polyline(points, Color(SWIRL, 0.75), 1.6, true)
	draw_circle(Vector2.ZERO, r, CORE)
	if _pulling:
		for i in 8:
			var f := fmod(_t * 0.9 + i / 8.0, 1.0)
			var distance := lerpf(_reach, r * 2.0, f)
			var angle := i * TAU / 8.0 + f * 2.2 + _t * 0.5
			var at := Vector2.from_angle(angle) * distance
			var tail := Vector2.from_angle(angle - 0.25) * (distance + 14.0)
			draw_line(tail, at, Color(SWIRL, 0.45 * f), 1.5)
