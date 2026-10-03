extends Node2D
## Frost Shell elite's ice: one translucent hexagonal ring per remaining layer.

const ICE := Color(0.6, 0.9, 1.0)
const EDGE := Color(0.9, 1.0, 1.0)
var _layers := 0
var _max := 1
var _t := 0.0


func set_layers(layers: int, max_layers: int) -> void:
	_layers = layers
	_max = maxi(1, max_layers)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	rotation = sin(_t * 0.7) * 0.15


func _draw() -> void:
	for i in _layers:
		var r := 36.0 + i * 9.0
		var ring := PackedVector2Array()
		for k in 7:
			ring.append(Vector2.from_angle(TAU * k / 6.0 + PI / 6.0) * r)
		draw_colored_polygon(ring, Color(ICE, 0.10))
		draw_polyline(ring, Color(EDGE, 0.75), 2.0)
