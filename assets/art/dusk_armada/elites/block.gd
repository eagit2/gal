extends Node2D
## A square block of the Scatter Titan's body. Flashes white when it is about to fly off.

const SIZE := 14.0
const FILL := Color(0.95, 0.78, 0.2)
const SHADE := Color(0.75, 0.55, 0.1)
const OUTLINE := Color(0.11, 0.09, 0.16)

var _flash := false
var _t := 0.0


func set_flash(on: bool) -> void:
	_flash = on


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var half := SIZE * 0.5
	var fill := Color.WHITE if _flash and fmod(_t, 0.16) < 0.08 else FILL
	draw_rect(Rect2(-half, -half, SIZE, SIZE), OUTLINE)
	draw_rect(Rect2(-half + 1.5, -half + 1.5, SIZE - 3.0, SIZE - 3.0), fill)
	draw_rect(Rect2(-half + 1.5, half - 4.5, SIZE - 3.0, 3.0), SHADE)
