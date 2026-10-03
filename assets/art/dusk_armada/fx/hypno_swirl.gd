extends Node2D
## Hypno swirl: two interleaved spiral arms, magenta and mint, turning around a bright eye. The Hypno
## Gun's shot, and (scaled up, faded) the spiral over a hypnotized enemy.

const RADIUS := 9.0
const ARM_A := Color(1.0, 0.35, 0.95)
const ARM_B := Color(0.55, 1.0, 0.8)
const SPIN := 7.0
const STEPS := 18

var _t := randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS * 1.15, Color(0.35, 0.05, 0.4, 0.35))
	for arm in 2:
		var points := PackedVector2Array()
		for i in STEPS + 1:
			var f := float(i) / STEPS
			var angle := -_t * SPIN + arm * PI + f * TAU * 1.25
			points.append(Vector2.from_angle(angle) * RADIUS * f)
		draw_polyline(points, ARM_A if arm == 0 else ARM_B, 2.0, true)
	draw_circle(Vector2.ZERO, RADIUS * 0.22, Color(1, 0.9, 1))
