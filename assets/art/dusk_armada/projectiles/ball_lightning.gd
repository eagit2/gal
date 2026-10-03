extends Node2D
## Ball Lightning: a pale blue glow with a white-hot core and jagged little bolts crackling out of
## it, redrawn at random every few frames so it flickers.

const RADIUS := 22.0
const GLOW := Color(0.45, 0.7, 1.0, 0.22)
const BODY := Color(0.6, 0.85, 1.0, 0.75)
const CORE := Color(0.95, 0.98, 1.0)
const BOLT := Color(0.8, 0.92, 1.0, 0.9)
const BOLTS := 5
const FLICKER := 0.06

var _t := 0.0
var _next := 0.0
var _bolts: Array[PackedVector2Array] = []


func _process(delta: float) -> void:
	_t += delta
	_next -= delta
	if _next <= 0.0:
		_next = FLICKER
		_bolts.clear()
		for i in BOLTS:
			_bolts.append(_bolt(randf() * TAU))
	queue_redraw()


func _bolt(angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	var length := RADIUS * randf_range(1.0, 1.5)
	for i in 5:
		var t := i / 4.0
		points.append(direction * lerpf(RADIUS * 0.3, length, t) + side * (0.0 if i == 0 else randf_range(-5.0, 5.0)))
	return points


func _draw() -> void:
	var pulse := 1.0 + 0.08 * sin(_t * 23.0)
	draw_circle(Vector2.ZERO, RADIUS * 1.35 * pulse, GLOW)
	draw_circle(Vector2.ZERO, RADIUS * pulse, BODY)
	draw_circle(Vector2.ZERO, RADIUS * 0.55, Color(0.8, 0.93, 1.0))
	draw_circle(Vector2.ZERO, RADIUS * 0.3, CORE)
	for bolt in _bolts:
		draw_polyline(bolt, BOLT, 2.0)
