extends Node2D
## Chip status look on an enemy: flickering embers while burning, a frost ring while chilled.
## Chunky pixel squares to match the Dusk Armada 16-bit style.

const EMBER := Color(1.0, 0.55, 0.15, 0.9)
const FROST := Color(0.55, 0.9, 1.0, 0.75)
const PIXEL := 3.0

var _burning := false
var _chilled := false
var _t := 0.0


func set_state(burning: bool, chilled: bool) -> void:
	_burning = burning
	_chilled = chilled
	visible = burning or chilled
	set_process(visible)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if _chilled:
		for i in 8:
			var a := TAU * i / 8.0 + _t * 0.8
			draw_rect(Rect2(Vector2.from_angle(a) * 20.0 - Vector2.ONE * PIXEL / 2.0, Vector2.ONE * PIXEL), FROST)
	if _burning:
		for i in 4:
			var phase := fmod(_t * 1.6 + i * 0.25, 1.0)
			var x := sin(i * 2.4 + _t * 3.0) * 10.0
			var c := EMBER
			c.a *= 1.0 - phase
			draw_rect(Rect2(Vector2(x, 6.0 - phase * 22.0), Vector2.ONE * PIXEL), c)
