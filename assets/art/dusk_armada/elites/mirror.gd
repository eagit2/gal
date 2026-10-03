extends Node2D
## Mirror Knight's mirror: a silver arc under the elite. Faint while down, glowing while it rises,
## bright and shimmering while up.

const SILVER := Color(0.85, 0.92, 1.0)
const OUTLINE := Color(0.11, 0.09, 0.16)

var _phase := 0
var _t := 0.0


func set_phase(phase: int) -> void:
	_phase = phase


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var from := PI * 0.15
	var to := PI * 0.85
	match _phase:
		0:
			draw_arc(Vector2.ZERO, 44.0, from, to, 20, Color(SILVER, 0.18), 3.0)
		1:
			draw_arc(Vector2.ZERO, 44.0, from, to, 20, Color(SILVER, 0.3 + 0.5 * absf(sin(_t * 18.0))), 5.0)
		2:
			draw_arc(Vector2.ZERO, 44.0, from, to, 20, OUTLINE, 10.0)
			draw_arc(Vector2.ZERO, 44.0, from, to, 20, SILVER, 6.0)
			draw_arc(Vector2.ZERO, 44.0, from + fmod(_t * 2.0, 1.0) * (to - from) * 0.8, from + fmod(_t * 2.0, 1.0) * (to - from) * 0.8 + 0.3, 6, Color.WHITE, 3.0)
