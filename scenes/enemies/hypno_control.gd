class_name HypnoControl
extends Node2D
## An enemy hit by the Hypno Gun: added as the enemy's child, it takes the enemy over (EnemyHold)
## for `duration` seconds. The enemy stops attacking the player (its ram hitbox is off) and turns
## on the nearest other enemy: either it hangs back and shoots at it (bolts that only hurt enemies)
## or it dives into it for RAM_DAMAGE, destroying itself. It stays hittable, glows with a pink tint
## and a spiral over it, and goes back to normal (and home to its slot) when the time runs out.

enum Mode { SHOOT, KAMIKAZE }

const NODE_NAME := &"HypnoControl"
const SWIRL := preload("res://assets/art/dusk_armada/fx/hypno_swirl.tscn")
const BOLT_SCENE := preload("res://scenes/projectiles/hypno_bolt.tscn")
const BASE_TIME := 4.0
const TINT := Color(1.0, 0.5, 1.0)
const SHOOT_EVERY := 0.6
const BOLT_SPEED := 460.0
const BOLT_DAMAGE := 1
const DIVE_SPEED := 340.0
const DIVE_TURN := 9.0
const RAM_RADIUS := 24.0
const RAM_DAMAGE := 6
const MIN_POS := Vector2(24, 40)
const MAX_POS := Vector2(516, 940)

var duration := BASE_TIME
var mode := Mode.SHOOT
var _left := BASE_TIME
var _enemy: Enemy
var _target: Node2D
var _cooldown := 0.25
var _velocity := Vector2.ZERO
var _tint := Color.WHITE


## Kamikaze for a `roll` under 0.5 (random in 0..1), else shoot.
static func pick_mode(roll: float) -> Mode:
	return Mode.KAMIKAZE if roll < 0.5 else Mode.SHOOT


## Whether a Hypno Gun hit takes over what it hit: a regular enemy not already hypnotized or
## trapped in a bubble.
static func can_hypnotize(is_enemy: bool, hypnotized: bool, trapped: bool) -> bool:
	return is_enemy and not hypnotized and not trapped


## Index of the point in `points` nearest `from`, or -1 when there are none.
static func nearest(from: Vector2, points: Array[Vector2]) -> int:
	var best := -1
	var best_distance := INF
	for i in points.size():
		var distance := from.distance_squared_to(points[i])
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


func _ready() -> void:
	name = NODE_NAME
	_enemy = get_parent() as Enemy
	_left = duration
	EnemyHold.grab(_enemy)
	_enemy.get_node(^"ContactHitbox").set_deferred(&"monitoring", false)
	var look := _enemy.get_node_or_null(^"Visual") as CanvasItem
	if look:
		_tint = look.modulate
		look.modulate = _tint * TINT
	var swirl: Node2D = SWIRL.instantiate()
	swirl.scale = Vector2.ONE * 1.8
	swirl.modulate.a = 0.75
	add_child(swirl)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_enemy) or GameState.freeze_left > 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		_wake()
		return
	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		_target = _find_target()
	if _target == null:
		return
	var to_target := _target.global_position - _enemy.global_position
	_enemy.rotation = lerp_angle(_enemy.rotation, to_target.angle() - PI / 2.0, minf(1.0, 8.0 * delta))
	if mode == Mode.KAMIKAZE:
		_dive(to_target, delta)
	else:
		_shoot(to_target, delta)


func _dive(to_target: Vector2, delta: float) -> void:
	_velocity = Steering.turn(_velocity, to_target, DIVE_TURN * delta, DIVE_SPEED)
	_enemy.position = (_enemy.position + _velocity * delta).clamp(MIN_POS, MAX_POS)
	if to_target.length() <= RAM_RADIUS:
		var health := _target.get_node_or_null(^"Health") as Health
		if health:
			health.take_damage(RAM_DAMAGE)
		_enemy.damage(_enemy.health().hp)


func _shoot(to_target: Vector2, delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = SHOOT_EVERY
	var parent := _enemy.get_parent()
	if parent == null:
		return
	var direction := to_target.normalized()
	var bolt: Shrapnel = Pools.acquire(BOLT_SCENE)
	bolt.launch(parent, _enemy.global_position + direction * 16.0, direction * BOLT_SPEED, BOLT_DAMAGE, BOLT_SCENE)
	bolt.ignore = _enemy


func _find_target() -> Node2D:
	var others: Array[Node2D] = []
	var points: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group(&"enemies") + get_tree().get_nodes_in_group(&"elites"):
		if node != _enemy and node.has_node(^"Health") and not node.is_queued_for_deletion():
			others.append(node as Node2D)
			points.append((node as Node2D).global_position)
	var i := nearest(_enemy.global_position, points)
	return others[i] if i >= 0 else null


func _wake() -> void:
	set_physics_process(false)
	var look := _enemy.get_node_or_null(^"Visual") as CanvasItem
	if look:
		look.modulate = _tint
	_enemy.get_node(^"ContactHitbox").set_deferred(&"monitoring", true)
	queue_free()
	EnemyHold.release(_enemy, self)
