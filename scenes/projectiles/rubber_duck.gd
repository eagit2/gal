class_name RubberDuck
extends Bullet
## Rubber Duck Gun shot: a squeaky duck that bounces off the left, right and top walls, up to
## `bounces` times (WeaponDef.bounces + the bounces stat, never more than MAX_WALL_BOUNCES). The
## first enemy ship it hits takes the damage and the duck is gone. It stays upright; the look tilts
## with its heading.

## Walls it bounces off: left, right and top edges (the bottom lets it leave).
const ARENA := Rect2(10, 60, 520, 2000)
const MAX_WALL_BOUNCES := 3

var _wall_bounces := 0
var _max_bounces := MAX_WALL_BOUNCES


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	pierce = 0  # Gone on its first enemy; never pierces.
	homing = 0.0
	_wall_bounces = 0
	_max_bounces = wall_bounce_limit(weapon.bounces + int(stats[&"bounces"]))
	rotation = 0.0


## Wall bounces a duck gets from `bounces` (weapon + stat): capped at MAX_WALL_BOUNCES.
static func wall_bounce_limit(bounces: int) -> int:
	return clampi(bounces, 0, MAX_WALL_BOUNCES)


## Velocity after the walls of `arena` at `pos`: x flips at the sides, y at the top. Only flips
## when moving into the wall, so it can't stick.
static func wall_bounce(pos: Vector2, vel: Vector2, arena: Rect2) -> Vector2:
	var out := vel
	if (pos.x < arena.position.x and out.x < 0.0) or (pos.x > arena.end.x and out.x > 0.0):
		out.x = -out.x
	if pos.y < arena.position.y and out.y < 0.0:
		out.y = -out.y
	return out


func _physics_process(delta: float) -> void:
	if _active and _wall_bounces < _max_bounces:
		var bounced := wall_bounce(position, velocity, ARENA)
		if bounced != velocity:
			velocity = bounced
			_wall_bounces += 1
			$Visual.call(&"squeak")
	super(delta)
	$Visual.call(&"heading", velocity)


func _on_hit(hurtbox: Hurtbox) -> void:
	$Visual.call(&"squeak")
	pierce = 0
	super(hurtbox)
