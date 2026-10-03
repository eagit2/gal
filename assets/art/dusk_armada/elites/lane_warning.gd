extends Node2D
## Meteor Caller's warning: translucent striped columns that flash faster as the meteors near.

const WARN := Color(1.0, 0.45, 0.3)

var _lanes: Array[float] = []
var _width := 70.0
var _progress := 0.0


func set_lanes(lanes: Array[float], width: float, progress: float) -> void:
	_lanes = lanes.duplicate()
	_width = width
	_progress = progress
	queue_redraw()


func _draw() -> void:
	if _lanes.is_empty():
		return
	var flash := 0.5 + 0.5 * sin(_progress * _progress * 40.0)
	for x in _lanes:
		draw_rect(Rect2(x - _width / 2.0, 0, _width, 960), Color(WARN, 0.08 + 0.12 * flash))
		var y := fmod(_progress * 300.0, 60.0) - 60.0
		while y < 960.0:
			draw_line(Vector2(x - _width / 2.0, y), Vector2(x + _width / 2.0, y + 30.0), Color(WARN, 0.25 + 0.25 * flash), 3.0)
			y += 60.0
		draw_line(Vector2(x - _width / 2.0, 0), Vector2(x - _width / 2.0, 960), Color(WARN, 0.6), 2.0)
		draw_line(Vector2(x + _width / 2.0, 0), Vector2(x + _width / 2.0, 960), Color(WARN, 0.6), 2.0)
