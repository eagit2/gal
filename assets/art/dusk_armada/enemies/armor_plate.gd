extends Node2D
## Plated enemy's front armor: an outlined steel bar with rivets.

const OUTLINE := Color(0.11, 0.09, 0.16)
const STEEL := Color(0.62, 0.66, 0.74)
const LIGHT := Color(0.86, 0.9, 0.96)


func _draw() -> void:
	draw_rect(Rect2(-21, -8, 42, 16), OUTLINE)
	draw_rect(Rect2(-19, -6, 38, 12), STEEL)
	draw_rect(Rect2(-19, -6, 38, 3), LIGHT)
	for x in [-13.0, 0.0, 13.0]:
		draw_circle(Vector2(x, 2), 1.6, OUTLINE)
