extends Node2D
## A blade diver's lock line: a thin pulsing sight line while it aims, then a bright cut that fades.

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0
var _fade := -1.0
var _life := 0.0


func set_line(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	queue_redraw()


## Turns the sight into a slash mark that fades out over `seconds`, then frees itself.
func fade(seconds: float) -> void:
	_fade = seconds
	_life = seconds
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _fade >= 0.0:
		_fade -= delta
		if _fade <= 0.0:
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	if _fade >= 0.0:
		var f := _fade / _life
		draw_line(_from, _to, Color(1.0, 0.5, 0.45, 0.35 * f), 9.0)
		draw_line(_from, _to, Color(1.0, 1.0, 1.0, f), 3.0)
		return
	var pulse := 0.5 + 0.5 * sin(_t * 40.0)
	draw_line(_from, _to, Color(1.0, 0.3, 0.3, 0.25 + 0.35 * pulse), 2.0)
	draw_circle(_to, 10.0 + 4.0 * pulse, Color(1.0, 0.3, 0.3, 0.3))
	draw_arc(_to, 16.0, 0.0, TAU, 20, Color(1.0, 0.6, 0.5, 0.8), 2.0)
