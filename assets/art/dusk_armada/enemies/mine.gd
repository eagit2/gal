extends Node2D
## Drifting mine: a spiked dark orb with a blinking red core; burst() draws the blast ring.

const OUTLINE := Color(0.11, 0.09, 0.16)
const SHELL := Color(0.34, 0.3, 0.38)
const CORE := Color(1.0, 0.32, 0.3)
const BLAST := Color(1.0, 0.75, 0.4)

var _t := 0.0
var _burst := -1.0
var _radius := 90.0


func burst(radius: float) -> void:
	_radius = radius
	_burst = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _burst >= 0.0:
		_burst += delta
	queue_redraw()


func _draw() -> void:
	if _burst >= 0.0:
		var f := minf(1.0, _burst / 0.3)
		draw_circle(Vector2.ZERO, _radius * f, Color(BLAST, 0.35 * (1.0 - f)))
		draw_arc(Vector2.ZERO, _radius * f, 0.0, TAU, 32, Color(BLAST, 1.0 - f), 4.0)
		return
	for i in 6:
		var d := Vector2.from_angle(TAU * i / 6.0 + _t * 0.8)
		draw_line(d * 8.0, d * 15.0, OUTLINE, 4.0)
		draw_line(d * 8.0, d * 14.0, SHELL, 2.0)
	draw_circle(Vector2.ZERO, 11.0, OUTLINE)
	draw_circle(Vector2.ZERO, 9.0, SHELL)
	draw_circle(Vector2.ZERO, 4.0, CORE if fmod(_t, 0.6) < 0.3 else CORE.darkened(0.5))
