class_name Enemy
extends Node2D
## Galaga-style enemy: enters along a path, settles into its formation slot, and dives at the player.
## Enemies without a slot (challenge stages) fly the path and leave.

enum State { ENTERING, TO_SLOT, IN_FORMATION, DIVING, RETURNING }

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
const NO_SLOT := Vector2i(-1, -1)
const TURN_RATE := 10.0
## Fraction of the dive path at which each shot is fired.
const SHOT_MARKS: Array[float] = [0.3, 0.42, 0.54]
const HIT_TINT := Color(1, 0.55, 0.85)

var def: EnemyDef
var difficulty: DifficultyDef
var formation: Formation
var slot := NO_SLOT
var target: Player
var entities: Node
var state := State.ENTERING
var _path: Curve2D
var _distance := 0.0
var _shots: Array[float] = []
var _visual: Node2D

@onready var _health: Health = $Health


func setup(enemy_def: EnemyDef, diff: DifficultyDef, entry_path: Curve2D, formation_slot: Vector2i, form: Formation) -> void:
	def = enemy_def
	difficulty = diff
	formation = form
	slot = formation_slot
	_follow(entry_path)
	position = entry_path.get_point_position(0)


func _ready() -> void:
	add_to_group(&"enemies")
	_visual = def.visual_scene.instantiate()
	_visual.name = "Visual"
	add_child(_visual)
	_health.reset(maxi(1, roundi(def.hp * difficulty.enemy_hp)))
	_health.died.connect(_on_died)
	_health.damaged.connect(func(_amount: int) -> void: _visual.modulate = HIT_TINT)
	# Ramming: the enemy is destroyed along with the player's life.
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: _health.take_damage(_health.hp))


func _physics_process(delta: float) -> void:
	match state:
		State.ENTERING, State.DIVING:
			_advance_path(delta)
		State.TO_SLOT, State.RETURNING:
			_fly_to_slot(delta)
		State.IN_FORMATION:
			position = formation.slot_position(slot)
			rotation = lerp_angle(rotation, 0.0, minf(1.0, TURN_RATE * delta))


func start_dive(player_position: Vector2) -> void:
	if state != State.IN_FORMATION:
		return
	state = State.DIVING
	_follow(DivePaths.build(position, player_position, def.behaviors))
	_shots = SHOT_MARKS.slice(0, def.dive_shots)


func _follow(curve: Curve2D) -> void:
	_path = curve
	_distance = 0.0


func _advance_path(delta: float) -> void:
	_distance += def.speed * delta
	var length := _path.get_baked_length()
	var previous := position
	position = _path.sample_baked(minf(_distance, length))
	_face(position - previous, delta)
	if state == State.DIVING and not _shots.is_empty() and _distance / length >= _shots[0]:
		_shots.pop_front()
		_fire()
	if _distance >= length:
		_on_path_end()


func _on_path_end() -> void:
	if slot == NO_SLOT:
		_leave()
	elif state == State.DIVING:
		# Re-enter from above the screen, Galaga style.
		position = Vector2(formation.slot_position(slot).x, -40.0)
		state = State.RETURNING
	else:
		state = State.TO_SLOT


func _fly_to_slot(delta: float) -> void:
	var goal := formation.slot_position(slot)
	var step := def.speed * delta
	if position.distance_to(goal) <= step:
		position = goal
		state = State.IN_FORMATION
		return
	_face(goal - position, delta)
	position = position.move_toward(goal, step)


## Sprites are drawn facing down (toward the player).
func _face(direction: Vector2, delta: float) -> void:
	if direction.length_squared() > 0.01:
		rotation = lerp_angle(rotation, direction.angle() - PI / 2.0, minf(1.0, TURN_RATE * delta))


func _fire() -> void:
	if not is_instance_valid(target) or not target.alive or global_position.y > target.global_position.y - 40.0:
		return
	var bullet: Bullet = Pools.acquire(ENEMY_BULLET)
	var direction := global_position.direction_to(target.global_position)
	var speed := def.bullet_speed * difficulty.enemy_bullet_speed
	bullet.launch(entities, global_position + direction * 14.0, direction * speed, 1, ENEMY_BULLET)


func _leave() -> void:
	remove_from_group(&"enemies")
	EventBus.enemy_escaped.emit(self)
	queue_free()


func _on_died() -> void:
	remove_from_group(&"enemies")
	var score := def.dive_score if state == State.DIVING else def.score
	EventBus.enemy_killed.emit(self, global_position, score)
	queue_free()
