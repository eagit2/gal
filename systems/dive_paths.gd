class_name DivePaths
extends RefCounted
## Builds dive curves at runtime: a hop out of formation, a swoop toward the player, then off the bottom.

const BOTTOM := 1010.0
const MIN_X := 30.0
const MAX_X := 510.0


static func build(start: Vector2, target: Vector2, behaviors: Array[StringName]) -> Curve2D:
	var side := -1.0 if start.x < 270.0 else 1.0
	var width := 1.6 if &"wide" in behaviors else 1.0
	var curve := Curve2D.new()
	curve.add_point(start, Vector2.ZERO, Vector2(0, -50))
	# Hop up and out, then turn down.
	var apex := Vector2(_clamp_x(start.x + side * 55.0 * width), start.y - 20.0)
	curve.add_point(apex, Vector2(0, -35), Vector2(0, 45))
	var aim_y := minf(target.y - 60.0, 860.0)
	var mid := Vector2(_clamp_x(lerpf(start.x, target.x, 0.5)), lerpf(apex.y, aim_y, 0.5))
	curve.add_point(mid, Vector2(side * 60.0 * width, -60), Vector2(-side * 60.0 * width, 60))
	if &"zigzag" in behaviors:
		var swing := 80.0 * width
		curve.add_point(Vector2(_clamp_x(target.x + swing), lerpf(mid.y, aim_y, 0.5)), Vector2(0, -40), Vector2(0, 40))
		curve.add_point(Vector2(_clamp_x(target.x - swing), aim_y), Vector2(0, -40), Vector2(0, 40))
	else:
		curve.add_point(Vector2(_clamp_x(target.x), aim_y), Vector2(0, -60), Vector2(0, 60))
	curve.add_point(Vector2(_clamp_x(target.x - side * 70.0), BOTTOM), Vector2(side * 30.0, -80), Vector2.ZERO)
	return curve


static func _clamp_x(x: float) -> float:
	return clampf(x, MIN_X, MAX_X)
