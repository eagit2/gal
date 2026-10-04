extends Node2D
## A soft shadow under the real Mirage: the tell that separates it from its holograms.


func _draw() -> void:
	for i in 4:
		var f := 1.0 - i / 4.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, 46.0 * f + 10.0, Color(0.0, 0.0, 0.05, 0.12))
