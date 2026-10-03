class_name BallLightning
extends Bullet
## Ball Lightning shot: a big crackling ball (sized by the ball_size stat) that drifts slowly up the
## screen, wandering from side to side at random but staying on screen. It passes through
## everything and shocks each enemy it touches for its damage every SHOCK_TICK seconds, with a
## lightning arc to it, so it grinds through a line of ships instead of killing them all at once.

const ARC_SCENE := preload("res://assets/art/dusk_armada/fx/chain_arc.tscn")
const SHOCK_TICK := 0.3
## Sideways wander: a new random drift every WANDER_TIME, steered toward at WANDER_ACCEL.
const WANDER_SPEED := 150.0
const WANDER_TIME := 0.45
const WANDER_ACCEL := 420.0
## Inside this far from a side wall the wander only picks drifts away from it.
const EDGE := 60.0
const MIN_X := 0.0
const MAX_X := 540.0

## Enemy instance id -> seconds until it can be shocked again (ids, so freed enemies are safe keys).
var _cooldowns := {}
var _drift := 0.0
var _wander_left := 0.0


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	scale = Vector2.ONE * float(stats[&"ball_size"])
	rotation = 0.0
	spent = true  # Never uses the one-hit path; it shocks what it overlaps on its own clock.
	_cooldowns.clear()
	_drift = 0.0
	_wander_left = 0.0


## A new sideways drift for a ball at `x` from a random `roll` in -1..1: any way in the middle,
## only back toward the centre near a wall.
static func wander_drift(x: float, roll: float) -> float:
	var drift := roll * WANDER_SPEED
	if x < MIN_X + EDGE:
		drift = absf(drift) + WANDER_SPEED * 0.3
	elif x > MAX_X - EDGE:
		drift = -absf(drift) - WANDER_SPEED * 0.3
	return drift


## Seconds left on each shock cooldown after `delta`; finished ones are dropped.
static func tick_cooldowns(cooldowns: Dictionary, delta: float) -> Dictionary:
	var out := {}
	for key: Variant in cooldowns:
		var left: float = cooldowns[key] - delta
		if left > 0.0:
			out[key] = left
	return out


func _physics_process(delta: float) -> void:
	if _active:
		_wander(delta)
		_shock(delta)
	super(delta)


func _wander(delta: float) -> void:
	_wander_left -= delta
	if _wander_left <= 0.0:
		_wander_left = WANDER_TIME * randf_range(0.6, 1.4)
		_drift = wander_drift(position.x, randf_range(-1.0, 1.0))
	velocity.x = move_toward(velocity.x, _drift, WANDER_ACCEL * delta)
	if (position.x < MIN_X + 20.0 and velocity.x < 0.0) or (position.x > MAX_X - 20.0 and velocity.x > 0.0):
		velocity.x = -velocity.x


func _shock(delta: float) -> void:
	_cooldowns = tick_cooldowns(_cooldowns, delta)
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or hurtbox.invulnerable:
			continue
		var target := hurtbox.get_parent() as Node2D
		if target == null or _cooldowns.has(target.get_instance_id()):
			continue
		_cooldowns[target.get_instance_id()] = SHOCK_TICK
		_arc_to(target.global_position)
		hurtbox.take_hit(self)
		StatusEffects.apply_hit(target, burn, chill, chain)


func _arc_to(point: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var arc: Node2D = ARC_SCENE.instantiate()
	parent.add_child(arc)
	arc.set(&"big", true)
	arc.call(&"connect_points", global_position, point)
