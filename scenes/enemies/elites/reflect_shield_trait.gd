class_name ReflectShieldTrait
extends EliteTrait
## A rotating dome sends every projectile back at you; it drops after each volley. Counter: fire
## through the open arc or right after the volley (rams and falling rocks ignore it).

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
## Physics layer of the player's shots.
const PLAYER_SHOTS := 4
const WARN := 0.5

@export var dome_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/reflect_dome.tscn")
@export var dome_radius := 62.0
@export var arc_open := 60
@export var rotate_speed := 0.8
@export var volley_interval := 4.0
@export var drop_time := 1.0
@export var reflect_speed_mult := 1.0
## At most one reflected shot per this many seconds.
@export var reflect_gap := 0.04


func begin(elite: Elite) -> void:
	var s := state(elite)
	s["angle"] = randf() * TAU
	s["t"] = 0.0
	s["drop"] = 0.0
	s["gap"] = 0.0
	var dome := Area2D.new()
	dome.collision_layer = 0
	dome.collision_mask = PLAYER_SHOTS
	dome.monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = dome_radius
	shape.shape = circle
	dome.add_child(shape)
	var visual: Node2D = dome_visual.instantiate()
	dome.add_child(visual)
	dome.area_entered.connect(_on_area_entered.bind(elite))
	elite.add_child(dome)
	s["dome"] = dome
	s["visual"] = visual


func tick(elite: Elite, delta: float) -> void:
	var s := state(elite)
	if not elite.entered:
		return
	s["angle"] += rotate_speed * delta
	s["gap"] -= delta
	if s["drop"] > 0.0:
		s["drop"] -= delta
	else:
		s["t"] += delta
		if s["t"] >= volley_interval:
			s["t"] = 0.0
			s["drop"] = drop_time
			elite.fire_fan()
	(s["visual"] as Node).call("set_dome", dome_radius, s["angle"], deg_to_rad(arc_open), s["drop"] > 0.0, s["t"] >= volley_interval - WARN)


## Whether a shot entering at `shot_angle` passes through the open arc centred on `gap_angle`.
static func in_open_arc(shot_angle: float, gap_angle: float, arc_degrees: float) -> bool:
	return absf(angle_difference(gap_angle, shot_angle)) <= deg_to_rad(arc_degrees) / 2.0


func _on_area_entered(area: Area2D, elite: Elite) -> void:
	var s := state(elite)
	var shot := area as Hitbox
	if shot == null or not elite.entered or s["drop"] > 0.0 or s["gap"] > 0.0:
		return
	var from := area.global_position
	if in_open_arc(elite.global_position.angle_to_point(from), s["angle"], arc_open):
		return
	if not is_instance_valid(elite.target) or not elite.target.alive:
		return
	s["gap"] = reflect_gap
	var speed := 300.0
	if shot is Bullet:
		speed = clampf((shot as Bullet).velocity.length() * 0.4, 220.0, 360.0)
		shot.spent = true
		(shot as Bullet).release()
	# Deferred: hits land inside a physics callback, where shots can't be added.
	_send_back.call_deferred(elite, from, speed * reflect_speed_mult)


func _send_back(elite: Elite, from: Vector2, speed: float) -> void:
	if not is_instance_valid(elite) or not is_instance_valid(elite.target) or not elite.entities.is_inside_tree():
		return
	var bullet: Bullet = Pools.acquire(ENEMY_BULLET)
	var velocity := from.direction_to(elite.target.global_position) * speed * elite.difficulty.enemy_bullet_speed
	bullet.launch(elite.entities, from, velocity, maxi(1, roundi(elite.level.damage)), ENEMY_BULLET)
