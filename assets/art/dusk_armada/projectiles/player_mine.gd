extends Node2D
## The player's mine: a round teal shell with stubby prongs and a blinking cyan core. burst() draws
## the blast ring at the blast radius; arm() resets it for reuse from the pool.

const OUTLINE := Color(0.06, 0.12, 0.16)
const SHELL := Color(0.25, 0.5, 0.56)
const CORE := Color(0.4, 1.0, 0.95)
const BLAST := Color(0.55, 1.0, 0.95)
const BURST_TIME := 0.3

var _t := 0.0
var _burst := -1.0
var _radius := 90.0


func arm() -> void:
	_burst = -1.0
	_t = 0.0


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
		var f := minf(1.0, _burst / BURST_TIME)
		draw_circle(Vector2.ZERO, _radius * f, Color(BLAST, 0.3 * (1.0 - f)))
		draw_arc(Vector2.ZERO, _radius * f, 0.0, TAU, 40, Color(BLAST, 1.0 - f), 4.0)
		draw_arc(Vector2.ZERO, _radius * f * 0.6, 0.0, TAU, 32, Color(1, 1, 1, 0.8 * (1.0 - f)), 2.0)
		return
	for i in 4:
		var d := Vector2.from_angle(TAU * i / 4.0 + PI / 4.0)
		draw_line(d * 8.0, d * 14.0, OUTLINE, 5.0)
		draw_line(d * 8.0, d * 13.0, SHELL.lightened(0.2), 3.0)
	draw_circle(Vector2.ZERO, 11.0, OUTLINE)
	draw_circle(Vector2.ZERO, 9.0, SHELL)
	var lit := fmod(_t, 0.5) < 0.25
	draw_circle(Vector2.ZERO, 4.5, CORE if lit else CORE.darkened(0.55))
	if lit:
		draw_circle(Vector2.ZERO, 8.0, Color(CORE, 0.25))
