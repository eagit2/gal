extends Line2D
## Volt chip: a short jagged electric arc between two enemies that fades out and frees itself.
## Big (Chain combo): a thick, longer-lived bolt with more kinks and a white-hot core.

const LIFE := 0.18
const SEGMENTS := 5
const JITTER := 6.0
const BIG_LIFE := 0.35
const BIG_SEGMENTS := 9
const BIG_JITTER := 16.0

var big := false


func connect_points(from: Vector2, to: Vector2) -> void:
	clear_points()
	var segments := BIG_SEGMENTS if big else SEGMENTS
	var spread := BIG_JITTER if big else JITTER
	var normal := (to - from).orthogonal().normalized()
	for i in segments + 1:
		var t := float(i) / segments
		var jitter := 0.0 if i == 0 or i == segments else randf_range(-spread, spread)
		add_point(from.lerp(to, t) + normal * jitter - global_position)
	if big:
		width = 7.0
		default_color = Color(0.55, 0.85, 1.0)
		var core := Line2D.new()
		core.points = points
		core.width = 2.5
		core.default_color = Color(1, 1, 1)
		add_child(core)
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, BIG_LIFE if big else LIFE)
	tween.tween_callback(queue_free)
