class_name WeaponDef
extends Resource

@export var id: StringName
@export var fire_rate: float = 6.0  # shots per second
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 900.0
@export var spread_count: int = 1
@export var spread_angle: float = 0.0
@export var damage: int = 1


## Shot directions in degrees from straight up, spread evenly across spread_angle.
func shot_angles() -> Array[float]:
	return fan(spread_count, spread_angle)


## `count` directions in degrees spread evenly across `angle`, centred on straight up.
static func fan(count: int, angle: float) -> Array[float]:
	var angles: Array[float] = []
	if count <= 1:
		angles.append(0.0)
		return angles
	for i in count:
		angles.append(lerpf(-angle / 2.0, angle / 2.0, i / (count - 1.0)))
	return angles
