extends Node2D
## Beams from an elite to the enemies it affects, plus a ring on each: Shield Warden's shields,
## the Puppeteer's strings.

@export var beam := Color(0.75, 0.55, 1.0)
@export var ring_radius := 18.0
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
		draw_line(Vector2.ZERO, local, Color(beam, pulse * 0.5), 5.0)
		draw_line(Vector2.ZERO, local, Color(Color.WHITE, pulse), 1.5)
		draw_arc(local, ring_radius, 0.0, TAU, 16, Color(beam, pulse), 2.0)
