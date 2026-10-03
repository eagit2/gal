class_name CompanionDrone
extends Node2D
## Companion drone (no-hit stage reward): trails the ship firing a pea shot (1 damage every 2 s).
## When an enemy is about to hit the ship it dives into it, destroying both. It has 1 HP: any
## enemy shot or ram that touches it destroys it.

const VISUAL := preload("res://assets/art/dusk_armada/player.tscn")
const PEA := preload("res://scenes/projectiles/drone_pea.tscn")
const OFFSET := Vector2(-44, 22)
const FOLLOW := 8.0
const FIRE_INTERVAL := 2.0
const PEA_SPEED := 700.0
const PEA_DAMAGE := 1
## Enemies this close to the ship count as about to hit it.
const DANGER_RADIUS := 150.0
const DIVE_SPEED := 720.0
const IMPACT_RADIUS := 20.0
const RAM_DAMAGE := 999
const HIT_RADIUS := 9.0

var player: Player
var entities: Node
var _fire := FIRE_INTERVAL
var _target: Node2D


func _ready() -> void:
	var look: Node2D = VISUAL.instantiate()
	look.scale = Vector2.ONE * 0.45
	look.modulate = Color(0.75, 1.0, 0.85)
	add_child(look)
	var hurtbox := Hurtbox.new()
	hurtbox.collision_layer = 1
	hurtbox.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = HIT_RADIUS
	shape.shape = circle
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.hurt.connect(func(_hitbox: Hitbox) -> void: _destroy())


## Index of the threat to ram: the closest enemy point within `radius` of the ship that is level
## with or above it, or -1.
static func pick_target(ship: Vector2, enemies: Array[Vector2], radius: float) -> int:
	var best := -1
	var best_distance := radius
	for i in enemies.size():
		var distance := enemies[i].distance_to(ship)
		if distance <= best_distance and enemies[i].y <= ship.y + 30.0:
			best = i
			best_distance = distance
	return best


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	if is_instance_valid(_target):
		_dive(delta)
		return
	global_position = global_position.lerp(player.global_position + OFFSET, minf(1.0, FOLLOW * delta))
	if not player.alive:
		return
	_target = _threat()
	_fire -= delta
	if _fire <= 0.0:
		_fire = FIRE_INTERVAL
		var pea: Bullet = Pools.acquire(PEA)
		pea.launch(entities, global_position + Vector2(0, -10), Vector2.UP * PEA_SPEED, PEA_DAMAGE, PEA)


func _threat() -> Node2D:
	var nodes: Array[Node2D] = []
	var points: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group(&"enemies") + get_tree().get_nodes_in_group(&"elites"):
		if node.has_node(^"Health"):
			nodes.append(node as Node2D)
			points.append((node as Node2D).global_position)
	var i := pick_target(player.global_position, points, DANGER_RADIUS)
	return nodes[i] if i >= 0 else null


func _dive(delta: float) -> void:
	var to := _target.global_position - global_position
	if to.length() <= IMPACT_RADIUS:
		(_target.get_node(^"Health") as Health).take_damage(RAM_DAMAGE)
		_destroy()
		return
	global_position += to.normalized() * minf(DIVE_SPEED * delta, to.length())
	rotation = to.angle() + PI / 2


func _destroy() -> void:
	if is_queued_for_deletion():
		return
	EventBus.companion_lost.emit(global_position)
	queue_free()
