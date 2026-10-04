extends Node2D
## Time Stop warning: the screen edges flash and a ring closes in on the player.

const SIZE := Vector2(540, 960)
const ICE := Color(0.6, 0.85, 1.0)

var _progress := 0.0
var _center := Vector2.ZERO


func _ready() -> void:
	top_level = true
	z_index = 50


## `progress` 0..1 through the warning, `center` the player's position.
func set_warning(progress: float, center: Vector2) -> void:
	_progress = progress
	_center = center
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_progress * 40.0)
	var edge := Color(ICE, (0.15 + 0.35 * pulse) * _progress)
	var w := 16.0
	draw_rect(Rect2(0, 0, SIZE.x, w), edge)
	draw_rect(Rect2(0, SIZE.y - w, SIZE.x, w), edge)
	draw_rect(Rect2(0, 0, w, SIZE.y), edge)
	draw_rect(Rect2(SIZE.x - w, 0, w, SIZE.y), edge)
	var r := lerpf(90.0, 34.0, _progress)
	draw_arc(_center, r, 0.0, TAU, 40, Color(0.11, 0.09, 0.16), 7.0)
	draw_arc(_center, r, 0.0, TAU, 40, Color(ICE, 0.6 + 0.4 * pulse), 4.0)
