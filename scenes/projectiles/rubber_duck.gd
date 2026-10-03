class_name RubberDuck
extends Bullet
## Rubber Duck Gun shot: a squeaky duck that bounces. Each enemy it hits squeaks it on toward the
## nearest other enemy (or back up at an angle when none is near), up to `bounces` more enemies
## (WeaponDef.bounces + the bounces stat); the left, right and top walls bounce it too, up to
## MAX_WALL_BOUNCES times. It stays upright; the look tilts with its heading.

## Walls it bounces off: left, right and top edges (the bottom lets it leave).
const ARENA := Rect2(10, 60, 520, 2000)
const MAX_WALL_BOUNCES := 4
## Enemies further than this from a hit aren't chased.
const CHASE_RADIUS := 320.0

var _wall_bounces := 0
var _last_hit: Node


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	pierce = weapon.bounces + int(stats[&"bounces"])  # Bounces use the pierce count; never real pierce.
	homing = 0.0
	_wall_bounces = 0
	_last_hit = null
	rotation = 0.0


## Velocity after the walls of `arena` at `pos`: x flips at the sides, y at the top. Only flips
## when moving into the wall, so it can't stick.
static func wall_bounce(pos: Vector2, vel: Vector2, arena: Rect2) -> Vector2:
	var out := vel
	if (pos.x < arena.position.x and out.x < 0.0) or (pos.x > arena.end.x and out.x > 0.0):
		out.x = -out.x
	if pos.y < arena.position.y and out.y < 0.0:
		out.y = -out.y
	return out


## Direction after hitting an enemy at `from`: toward the nearest of `targets` within
## CHASE_RADIUS, else up and away at 45° on the side it was heading (`heading_x`).
static func bounce_direction(from: Vector2, targets: Array[Vector2], heading_x: float) -> Vector2:
	var best := Vector2.ZERO
	var best_distance := CHASE_RADIUS * CHASE_RADIUS
	for point in targets:
		var distance := from.distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best = point
	if best != Vector2.ZERO:
		return from.direction_to(best)
	return Vector2(1.0 if heading_x >= 0.0 else -1.0, -1.0).normalized()


func _physics_process(delta: float) -> void:
	if _active and _wall_bounces < MAX_WALL_BOUNCES:
		var bounced := wall_bounce(position, velocity, ARENA)
		if bounced != velocity:
			velocity = bounced
			_wall_bounces += 1
			$Visual.call(&"squeak")
	super(delta)
	$Visual.call(&"heading", velocity)


func _on_hit(hurtbox: Hurtbox) -> void:
	var bounces_on := pierce > 0
	_last_hit = hurtbox.get_parent()
	super(hurtbox)
	$Visual.call(&"squeak")
	if bounces_on and _active:
		velocity = bounce_direction(global_position, _targets(), velocity.x) * velocity.length()


func _targets() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group(&"enemies") + get_tree().get_nodes_in_group(&"elites"):
		if node != _last_hit:
			points.append((node as Node2D).global_position)
	return points
