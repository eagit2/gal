extends Node2D
## Tractor beam cone below a captor: grows in, then pulses with bands sliding up.

const COLOR := Color(0.55, 0.85, 1.0)
const LENGTH := 520.0
const HALF_WIDTH := 26.0
const SPREAD := 0.32
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var grow := minf(1.0, _t / 0.5)
	var length := LENGTH * grow
	var far := HALF_WIDTH + length * SPREAD
	draw_colored_polygon(PackedVector2Array([Vector2(-HALF_WIDTH, 10), Vector2(HALF_WIDTH, 10), Vector2(far, length), Vector2(-far, length)]), Color(COLOR, 0.14))
	for i in 9:
		var y := fmod(length - fmod(_t * 160.0 + i * 60.0, length), length)
		var w := HALF_WIDTH + y * SPREAD
		draw_line(Vector2(-w, y), Vector2(w, y), Color(COLOR, 0.55 * (1.0 - y / LENGTH)), 3.0)
