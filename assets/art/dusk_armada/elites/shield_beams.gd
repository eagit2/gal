extends Node2D
## Shield Warden's beams to the enemies it protects, plus a bubble on each.

const BEAM := Color(0.75, 0.55, 1.0)
var _targets: Array[Vector2] = []
var _t := 0.0


## Global positions of the shielded enemies.
func set_targets(points: Array[Vector2]) -> void:
	_targets = points
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta


func _draw() -> void:
	var pulse := 0.55 + 0.25 * sin(_t * 8.0)
	for p in _targets:
		var local := to_local(p)
		draw_line(Vector2.ZERO, local, Color(BEAM, pulse * 0.5), 5.0)
		draw_line(Vector2.ZERO, local, Color(Color.WHITE, pulse), 1.5)
		draw_arc(local, 18.0, 0.0, TAU, 16, Color(BEAM, pulse), 2.0)
