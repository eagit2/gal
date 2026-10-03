class_name StatusEffects
extends Node
## Chip effects on an enemy, added the first time a shot with burn/chill/chain hits it.
## Burn: 1 damage per second; each hit adds BURN_TIME per level (duration stacks, damage doesn't).
## Chill: slows the enemy (CHILL_SLOW per level, capped) for CHILL_TIME. Chain: the hit arcs to
## that many other enemies within CHAIN_RADIUS for 1 damage each. The enemy's movement reads
## speed_scale(); the look lives in the status FX visual (assets/art/dusk_armada/fx).

const NODE_NAME := &"Status"
const FX_SCENE := preload("res://assets/art/dusk_armada/fx/status_fx.tscn")
const ARC_SCENE := preload("res://assets/art/dusk_armada/fx/chain_arc.tscn")
const BURN_TIME := 3.0
const BURN_TICK := 1.0
## Burn never queues up more than this many levels' worth of seconds.
const BURN_CAP_LEVELS := 2
const CHILL_SLOW := 0.3
const CHILL_CAP := 0.6
const CHILL_TIME := 2.0
const CHAIN_RADIUS := 90.0
const CHAIN_DAMAGE := 1

var burn_left := 0.0
var chill_left := 0.0
var slow := 0.0
var _burn_tick := BURN_TICK
var _fx: Node2D


## Burn seconds left after a hit at `level`.
static func burn_after(left: float, level: int) -> float:
	return minf(left + BURN_TIME * level, BURN_TIME * level * BURN_CAP_LEVELS)


## Fraction of speed lost while chilled at `level`.
static func chill_slow(level: int) -> float:
	return clampf(CHILL_SLOW * level, 0.0, CHILL_CAP)


## Indices of the `count` nearest `points` within `radius` of `origin` (closest first).
static func chain_targets(origin: Vector2, points: Array[Vector2], count: int, radius: float) -> Array[int]:
	var near: Array[int] = []
	for i in points.size():
		if points[i].distance_to(origin) <= radius:
			near.append(i)
	near.sort_custom(func(a: int, b: int) -> bool: return points[a].distance_squared_to(origin) < points[b].distance_squared_to(origin))
	return near.slice(0, maxi(count, 0))


## Movement multiplier for an enemy: 1 unless it is chilled.
static func speed_scale(enemy: Node) -> float:
	var status := enemy.get_node_or_null(NodePath(NODE_NAME)) as StatusEffects
	return 1.0 if status == null else 1.0 - status.slow


## A player shot with chip effects hit `enemy` (the hurtbox owner).
static func apply_hit(enemy: Node2D, burn: int, chill: int, chain: int) -> void:
	if enemy == null or (burn <= 0 and chill <= 0 and chain <= 0):
		return
	if burn > 0 or chill > 0:
		var status := of(enemy)
		if burn > 0:
			status.burn_left = burn_after(status.burn_left, burn)
		if chill > 0:
			status.chill_left = CHILL_TIME
			status.slow = maxf(status.slow, chill_slow(chill))
		status._sync_fx()
	if chain > 0:
		_arc(enemy, chain)


## The enemy's status node, created on first use.
static func of(enemy: Node) -> StatusEffects:
	var status := enemy.get_node_or_null(NodePath(NODE_NAME)) as StatusEffects
	if status == null:
		status = StatusEffects.new()
		status.name = NODE_NAME
		enemy.add_child(status)
	return status


static func _arc(enemy: Node2D, count: int) -> void:
	var tree := enemy.get_tree()
	var others: Array[Node2D] = []
	var points: Array[Vector2] = []
	for node in tree.get_nodes_in_group(&"enemies") + tree.get_nodes_in_group(&"elites"):
		if node != enemy and node.has_node(^"Health"):
			others.append(node as Node2D)
			points.append((node as Node2D).global_position)
	for i in chain_targets(enemy.global_position, points, count, CHAIN_RADIUS):
		var arc: Node2D = ARC_SCENE.instantiate()
		enemy.get_parent().add_child(arc)
		arc.call(&"connect_points", enemy.global_position, points[i])
		(others[i].get_node(^"Health") as Health).take_damage(CHAIN_DAMAGE)


func _physics_process(delta: float) -> void:
	if burn_left > 0.0:
		burn_left -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick += BURN_TICK
			var health := get_parent().get_node_or_null(^"Health") as Health
			if health:
				health.take_damage(1)
		if burn_left <= 0.0:
			_burn_tick = BURN_TICK
			_sync_fx()
	if chill_left > 0.0:
		chill_left -= delta
		if chill_left <= 0.0:
			slow = 0.0
			_sync_fx()


func _sync_fx() -> void:
	if _fx == null:
		_fx = FX_SCENE.instantiate()
		get_parent().add_child(_fx)
	_fx.call(&"set_state", burn_left > 0.0, slow > 0.0)
