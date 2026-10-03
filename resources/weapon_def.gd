class_name WeaponDef
extends Resource

@export var id: StringName
@export var fire_rate: float = 6.0  # shots per second
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 900.0
@export var spread_count: int = 1
@export var spread_angle: float = 0.0
@export var damage: int = 1
## Pixels between parallel barrels (twin cannon); 0 fires every shot from the muzzle.
@export var spacing: float = 0.0
## Enemies each shot passes through, and its turn rate toward enemies (radians per second).
@export var pierce: int = 0
@export var homing: float = 0.0
## Pixels a shot flies before it fizzles (flak pellets); 0 = until it leaves the screen.
@export var max_range: float = 0.0
## Special shots (their projectile scene's script reads these; ordinary shots ignore them):
## wall bounces a rubber duck gets (at most 3), pieces a scrap ball breaks into, and a
## mine's blast radius in pixels. Run stats bounces, shrapnel and blast_radius add to them.
@export var bounces: int = 0
@export var shrapnel: int = 0
@export var blast_radius: float = 0.0
## Most of this weapon's shots out at once (mines); 0 = no cap. The max_active stat adds to it.
@export var active_cap: int = 0


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


## Sideways offset of each of `count` parallel barrels `gap` px apart, centred on the muzzle.
static func barrels(count: int, gap: float) -> Array[float]:
	var offsets: Array[float] = []
	var n := maxi(count, 1)
	for i in n:
		offsets.append((i - (n - 1) / 2.0) * gap)
	return offsets


## How many shots may be out at once with `bonus` (the max_active stat); 0 = no cap.
func cap(bonus: int) -> int:
	return active_cap + bonus if active_cap > 0 else 0


## Whether another shot may go out with `active` already out under `limit` (0 = no cap).
static func can_fire(active: int, limit: int) -> bool:
	return limit <= 0 or active < limit
