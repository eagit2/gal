class_name GravityPool
extends Node2D
## A gravity pool lobbed by the Gravity Well: flies to a spot, then for its life drags the player's
## ship and bends every player shot inside its radius toward its core, absorbing shots that reach
## it. Counter: stay out of it and fire around it.

const FLIGHT_MAX := 2.5
const FADE := 0.4

var _player: Player
var _goal := Vector2.ZERO
var _speed := 120.0
var _life := 4.0
var _radius := 110.0
var _ship_pull := 140.0
var _shot_pull := 420.0
var _landed := false
var _flight := 0.0


func setup(player: Player, goal: Vector2, speed: float, life: float, radius: float, ship_pull: float, shot_pull: float) -> void:
	_player = player
	_goal = goal
	_speed = speed
	_life = life
	_radius = radius
	_ship_pull = ship_pull
	_shot_pull = shot_pull


## Velocity of a shot at `at` after `delta` seconds of pull toward `center`.
static func bend(velocity: Vector2, at: Vector2, center: Vector2, accel: float, delta: float) -> Vector2:
	return velocity + at.direction_to(center) * accel * delta


## Where a ship at `from` ends up after `delta` seconds of drift toward `center` (never past it).
static func drift(from: Vector2, center: Vector2, speed: float, delta: float) -> Vector2:
	return from.move_toward(center, speed * delta)


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	if not _landed:
		_flight += delta
		position = position.move_toward(_goal, _speed * delta)
		_landed = position.is_equal_approx(_goal) or _flight >= FLIGHT_MAX
	else:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		_pull(delta)
	($Visual as Node2D).call(&"set_state", _radius, _landed, 1.0 if _life > FADE else maxf(_life, 0.0) / FADE)


func _pull(delta: float) -> void:
	if is_instance_valid(_player) and _player.alive and _player.global_position.distance_to(global_position) <= _radius:
		_player.global_position = drift(_player.global_position, global_position, _ship_pull, delta)
	var reach := _radius * _radius
	var core := _radius * 0.12
	for node in get_parent().get_children():
		var shot := node as Bullet
		if shot == null or shot.weapon_id == &"" or shot.global_position.distance_squared_to(global_position) > reach:
			continue
		if shot.global_position.distance_to(global_position) <= core:
			shot.release()
			continue
		shot.velocity = bend(shot.velocity, shot.global_position, global_position, _shot_pull, delta)
		shot.rotation = shot.velocity.angle() + PI / 2
