extends Node2D
## A gravity pool: dark core with rings spiralling inward. Dim while flying, full once landed.

const VIOLET := Color(0.7, 0.45, 1.0)

var _radius := 110.0
var _landed := false
var _fade := 1.0
var _t := 0.0


func set_state(radius: float, landed: bool, fade: float) -> void:
	_radius = radius
	_landed = landed
	_fade = fade


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if not _landed:
		draw_circle(Vector2.ZERO, 10.0, Color(VIOLET, 0.8 * _fade))
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 40, Color(VIOLET, 0.25 * _fade), 1.5)
		return
	draw_circle(Vector2.ZERO, _radius, Color(0.25, 0.1, 0.4, 0.22 * _fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, Color(VIOLET, 0.6 * _fade), 2.5)
	for i in 3:
		var f := fmod(_t * 0.7 + i / 3.0, 1.0)
		var r := lerpf(_radius, 12.0, f)
		draw_arc(Vector2.ZERO, r, _t * 3.0 + i, _t * 3.0 + i + PI * 1.3, 24, Color(VIOLET, f * 0.8 * _fade), 2.0)
	draw_circle(Vector2.ZERO, 11.0, Color(0.05, 0.0, 0.1, _fade))
