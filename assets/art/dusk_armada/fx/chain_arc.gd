extends Line2D
## Volt chip: a short jagged electric arc between two enemies that fades out and frees itself.

const LIFE := 0.18
const SEGMENTS := 5
const JITTER := 6.0


func connect_points(from: Vector2, to: Vector2) -> void:
	clear_points()
	var normal := (to - from).orthogonal().normalized()
	for i in SEGMENTS + 1:
		var t := float(i) / SEGMENTS
		var jitter := 0.0 if i == 0 or i == SEGMENTS else randf_range(-JITTER, JITTER)
		add_point(from.lerp(to, t) + normal * jitter - global_position)
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, LIFE)
	tween.tween_callback(queue_free)
