extends Node2D
## Sweeper's laser, drawn straight down: a faint flickering aim line, then a hot core beam.

const HOT := Color(1.0, 0.35, 0.3)
const LENGTH := 1130.0

var _mode := 0
var _t := 0.0


func set_mode(mode: int) -> void:
	_mode = mode


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	match _mode:
		1:
			draw_line(Vector2(0, 30), Vector2(0, LENGTH), Color(HOT, 0.25 + 0.3 * absf(sin(_t * 20.0))), 2.0)
		2:
			draw_line(Vector2(0, 30), Vector2(0, LENGTH), Color(HOT, 0.35), 18.0)
			draw_line(Vector2(0, 30), Vector2(0, LENGTH), Color(1.0, 0.8, 0.7), 6.0)
