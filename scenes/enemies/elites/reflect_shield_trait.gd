class_name ReflectShieldTrait
extends EliteTrait
## A dome reflects every shot back at you for `reflect_time` seconds, then overloads and flickers
## out for `down_time` seconds before it reboots. Counter: hold fire while it is up, then unload
## during the overload (rams and falling rocks ignore it).

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
## Physics layer of the player's shots.
const PLAYER_SHOTS := 4
## Seconds of flicker before the dome overloads.
const WARN := 0.8

@export var dome_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/reflect_dome.tscn")
@export var dome_radius := 62.0
@export var reflect_time := 5.0
@export var down_time := 2.0
@export var reflect_speed_mult := 1.0
## At most one reflected shot per this many seconds.
@export var reflect_gap := 0.04


func begin(elite: Elite) -> void:
	var s := state(elite)
	s["up"] = reflect_time
	s["down"] = 0.0
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
	s["visual"] = visual


func tick(elite: Elite, delta: float) -> void:
	var s := state(elite)
	if not elite.entered:
		return
	s["gap"] -= delta
	var cycle := step(s["up"], s["down"], delta, reflect_time, down_time)
	s["up"] = cycle.x
	s["down"] = cycle.y
	(s["visual"] as Node).call("set_dome", dome_radius, 0.0, 0.0, s["down"] > 0.0, s["down"] <= 0.0 and s["up"] <= WARN)


## Advances the shield cycle: returns (time left up, time left down). Up counts down to the
## overload, then down counts down to the reboot.
static func step(up: float, down: float, delta: float, up_time: float, down_len: float) -> Vector2:
	if down > 0.0:
		down -= delta
		if down <= 0.0:
			return Vector2(up_time, 0.0)
		return Vector2(0.0, down)
	up -= delta
	if up <= 0.0:
		return Vector2(0.0, down_len)
	return Vector2(up, 0.0)


func _on_area_entered(area: Area2D, elite: Elite) -> void:
	var s := state(elite)
	var shot := area as Hitbox
	if shot == null or not elite.entered or s["down"] > 0.0 or s["gap"] > 0.0:
		return
	if not is_instance_valid(elite.target) or not elite.target.alive:
		return
	s["gap"] = reflect_gap
	var from := area.global_position
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
