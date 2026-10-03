class_name Bullet
extends Hitbox
## Pooled projectile. Flies straight, or curves toward the nearest enemy when homing.
## Returns to the pool on hit (unless it still pierces) or when off screen.

const BOUNDS := Rect2(-40, -40, 620, 1040)
const RETARGET_TIME := 0.15

## Player shots report hits and misses (Lock-On meter).
@export var reports_miss := false
## Enemy shots the player can graze (Graze meter).
@export var grazeable := false
var velocity := Vector2.ZERO
## Enemies this shot passes through before it is used up.
var pierce := 0
## Turn rate toward the nearest enemy, radians per second.
var homing := 0.0
## Set once the player has grazed this shot.
var grazed := false
var _pool_scene: PackedScene
var _active := false
var _target: Node2D
var _retarget := 0.0


func _ready() -> void:
	super()
	single_hit = true
	hit.connect(_on_hit)


func launch(parent: Node, from: Vector2, vel: Vector2, dmg: int, pool_scene: PackedScene, pierces := 0, turn_rate := 0.0) -> void:
	_pool_scene = pool_scene
	velocity = vel
	damage = dmg
	pierce = pierces
	homing = turn_rate
	grazed = false
	spent = false
	_active = true
	_target = null
	_retarget = 0.0
	rotation = vel.angle() + PI / 2
	if grazeable:
		add_to_group(&"enemy_shots")
	parent.add_child(self)
	global_position = from


func _physics_process(delta: float) -> void:
	if grazeable and GameState.freeze_left > 0.0:
		return  # Enemy shots hang in the air during a Cryo Pulse.
	if homing > 0.0 and _active:
		_steer(delta)
	position += velocity * delta
	if _active and not BOUNDS.has_point(position):
		if reports_miss:
			EventBus.shot_missed.emit()
		release()


func _steer(delta: float) -> void:
	_retarget -= delta
	if _retarget <= 0.0 or not is_instance_valid(_target):
		_retarget = RETARGET_TIME
		_target = _nearest_enemy()
	if is_instance_valid(_target) and _target.global_position.y < global_position.y:
		velocity = Steering.turn(velocity, _target.global_position - global_position, homing * delta, velocity.length())
		rotation = velocity.angle() + PI / 2


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Node2D
		var distance := enemy.global_position.distance_squared_to(global_position)
		if distance < best_distance and enemy.global_position.y < global_position.y:
			best = enemy
			best_distance = distance
	return best


func _on_hit(_hurtbox: Hurtbox) -> void:
	if reports_miss:
		EventBus.shot_hit.emit()
	if pierce > 0:
		pierce -= 1
		spent = false
		return
	release()


func release() -> void:
	if not _active:
		return
	_active = false
	if grazeable:
		remove_from_group(&"enemy_shots")
	Pools.release.call_deferred(_pool_scene, self)
