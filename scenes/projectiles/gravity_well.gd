class_name GravityWell
extends Bullet
## Gravity Gun shot: a small black hole. When it hits an enemy it deals its damage, then stops right
## there and for its pull time drags every regular enemy within its pull radius toward itself
## (GravityPull holds them; they stay hittable). Then it fades out. Pull time and radius are
## BASE_PULL_TIME / BASE_PULL_RADIUS plus the pull_time / pull_radius stats.

const BASE_PULL_TIME := 2.0
const BASE_PULL_RADIUS := 150.0
const PULL_SPEED := 190.0
## Pulled enemies stop this far from the core instead of piling onto one point.
const HOLD_DISTANCE := 22.0
const FADE_TIME := 0.35

var _pull_time := BASE_PULL_TIME
var _pull_radius := BASE_PULL_RADIUS
var _anchored := false
var _left := 0.0
var _fade := 0.0
## GravityPull nodes this well holds (untyped: a pulled enemy may be freed mid-pull).
var _pulls: Array = []


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	rotation = 0.0
	_pull_time = BASE_PULL_TIME + float(stats[&"pull_time"])
	_pull_radius = BASE_PULL_RADIUS + float(stats[&"pull_radius"])
	_anchored = false
	_left = 0.0
	_fade = 0.0
	_pulls.clear()
	$Visual.modulate.a = 1.0
	$Visual.call(&"set_pulling", false, _pull_radius)


## Where an enemy at `from` ends up after a pull of `step` pixels toward `well`, stopping `hold`
## pixels short of it.
static func pull_step(from: Vector2, well: Vector2, step: float, hold: float) -> Vector2:
	var distance := from.distance_to(well)
	if distance <= hold:
		return from
	return from.move_toward(well, minf(step, distance - hold))


func _physics_process(delta: float) -> void:
	if _anchored and _active:
		if _left > 0.0:
			_left -= delta
			_pull(delta)
			if _left <= 0.0:
				_let_go()
		else:
			_fade -= delta
			$Visual.modulate.a = clampf(_fade / FADE_TIME, 0.0, 1.0)
			if _fade <= 0.0:
				release()
				return
	super(delta)


func _on_hit(hurtbox: Hurtbox) -> void:
	StatusEffects.apply_hit(hurtbox.get_parent() as Node2D, burn, chill, chain)
	if reports_miss:
		EventBus.shot_hit.emit()
	velocity = Vector2.ZERO
	_anchored = true
	_left = _pull_time
	_fade = FADE_TIME
	$Visual.call(&"set_pulling", true, _pull_radius)


func _pull(delta: float) -> void:
	var reach := _pull_radius * _pull_radius
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.global_position.distance_squared_to(global_position) > reach:
			continue
		var pull := enemy.get_node_or_null(NodePath(GravityPull.NODE_NAME)) as GravityPull
		if pull == null:
			if EnemyHold.held_by_other(enemy):
				continue  # In a bubble or hypnotized: leave it be.
			pull = GravityPull.new()
			enemy.add_child(pull)
		if not pull.wells.has(self):
			pull.wells.append(self)
			_pulls.append(pull)
		enemy.global_position = pull_step(enemy.global_position, global_position, PULL_SPEED * delta, HOLD_DISTANCE)


func _let_go() -> void:
	for pull: Variant in _pulls:
		if is_instance_valid(pull):
			(pull as GravityPull).drop(self)
	_pulls.clear()
	$Visual.call(&"set_pulling", false, _pull_radius)


func release() -> void:
	if not _pulls.is_empty():
		_let_go()
	super()
