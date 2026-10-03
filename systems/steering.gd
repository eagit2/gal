class_name Steering
extends RefCounted
## Small vector helpers for enemy brains.


## Rotates `current` toward `desired` by at most `max_radians`, and gives it length `speed`.
static func turn(current: Vector2, desired: Vector2, max_radians: float, speed: float) -> Vector2:
	if desired.length_squared() < 0.0001:
		return current.normalized() * speed
	if current.length_squared() < 0.0001:
		return desired.normalized() * speed
	var angle := current.angle_to(desired)
	return current.normalized().rotated(clampf(angle, -max_radians, max_radians)) * speed


## Push away from neighbours closer than `radius`, strongest when overlapping.
static func separation(from: Vector2, others: Array[Vector2], radius: float) -> Vector2:
	var push := Vector2.ZERO
	for other in others:
		var offset := from - other
		var distance := offset.length()
		if distance > 0.01 and distance < radius:
			push += offset / distance * (1.0 - distance / radius)
	return push
