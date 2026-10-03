extends Node2D
## Gravity Well: rings spiralling into the core. Violet while shielded, gold while open.

const CLOSED := Color(0.7, 0.45, 1.0)
const OPEN := Color(1.0, 0.85, 0.4)

var _open := false
var _t := 0.0


func set_open(open: bool) -> void:
	_open = open


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var color := OPEN if _open else CLOSED
	for i in 3:
		var f := fmod(_t * 0.6 + i / 3.0, 1.0)
		var r := lerpf(70.0, 20.0, f)
		draw_arc(Vector2.ZERO, r, _t * 2.0 + i, _t * 2.0 + i + PI * 1.4, 24, Color(color, f * 0.7), 2.5)
	if not _open:
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 24, Color(color, 0.8), 3.0)
