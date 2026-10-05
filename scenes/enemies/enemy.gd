class_name Enemy
extends Node2D
## Galaga-style enemy: flies in along its entry path, settles into its formation slot, then attacks
## when the DiveController sends it. Attacks are steered live by the EnemyDef's brain, not by fixed
## paths. Enemies without a slot (challenge stages) fly the entry path and leave.

enum State { ENTERING, TO_SLOT, IN_FORMATION, DIVING, RETURNING }

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
const ESCORT_BRAIN := preload("res://data/brains/escort.tres")
const NO_SLOT := Vector2i(-1, -1)
const TURN_RATE := 10.0
const TOP := -40.0
const BOTTOM := 1010.0
const MIN_X := 24.0
const MAX_X := 516.0
const SEPARATION_RADIUS := 34.0
const SEPARATION_FORCE := 260.0

var def: EnemyDef
var difficulty: DifficultyDef
var formation: Formation
var slot := NO_SLOT
var target: Player
var entities: Node
var state := State.ENTERING

# Attack state, read and written by brains.
var brain: EnemyBrain
var velocity := Vector2.ZERO
var phase := 0
var phase_time := 0.0
var attack_time := 0.0
var fire_cooldown := 0.0
var shots_left := 0
## Stage aggression when the attack started; brains scale risk-taking by it.
var aggression := 1.0
## Stage multiplier on kamikaze dive speed (SwarmerBrain reads it).
var kamikaze_speed := 1.0
## Per-enemy personality in 0..1, so two enemies with the same brain don't fly identically.
var quirk := randf()
## Face the player instead of the direction of travel (strafers).
var aim_facing := false
var leader: Enemy
var escort_offset := Vector2.ZERO
## Per-enemy state for the EnemyDef's traits, keyed by trait (EnemyTrait.state).
var trait_state := {}
## Stage HP multiplier, set by the StageRunner before it joins the tree.
var hp_scale := 1.0

var _path: Curve2D
var _distance := 0.0
var _visual: Node2D
var _tint := Color.WHITE

@onready var _health: Health = $Health


func setup(enemy_def: EnemyDef, diff: DifficultyDef, entry_path: Curve2D, formation_slot: Vector2i, form: Formation) -> void:
	def = enemy_def
	difficulty = diff
	formation = form
	slot = formation_slot
	_path = entry_path
	_distance = 0.0
	position = entry_path.get_point_position(0)


func _ready() -> void:
	add_to_group(&"enemies")
	_visual = def.visual_scene.instantiate()
	_visual.name = "Visual"
	_visual.scale *= def.visual_scale
	_visual.modulate *= def.tint
	add_child(_visual)
	_tint = _visual.modulate
	_health.reset(maxi(1, roundi(def.hp * difficulty.enemy_hp * hp_scale)))
	_health.died.connect(_on_died)
	# Ramming (or hitting the player's shield) destroys the enemy.
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: _health.take_damage(_health.hp))
	for t in def.all_traits():
		t.begin(self)


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return  # Cryo Pulse: hold still (still hittable).
	delta *= StatusEffects.speed_scale(self)  # Frost chip
	match state:
		State.ENTERING:
			_advance_path(delta)
		State.DIVING:
			_attack(delta)
		State.TO_SLOT, State.RETURNING:
			_fly_to_slot(delta)
		State.IN_FORMATION:
			position = formation.slot_position(slot)
			rotation = lerp_angle(rotation, 0.0, minf(1.0, TURN_RATE * delta))
	for t in def.all_traits():
		t.tick(self, delta)


# --- Attacks ---------------------------------------------------------------------------------

## Leaves formation to attack with the type's brain, or `attack_brain` (capture runs).
func start_attack(player: Player, stage_aggression: float, attack_brain: EnemyBrain = null) -> void:
	var chosen := attack_brain if attack_brain else def.brain
	if state != State.IN_FORMATION or chosen == null:
		return
	target = player
	aggression = stage_aggression
	_begin_attack(chosen)


## Attacks right away from wherever it is (spawned by a hive pod: no slot, freed when done).
func launch(player: Player, stage_aggression: float, attack_brain: EnemyBrain) -> void:
	target = player
	aggression = stage_aggression
	_begin_attack(attack_brain)


## Breaks off the current attack and flies home (a Puppeteer let go).
func recall() -> void:
	if state == State.DIVING:
		_end_attack()


## Called by a squad leader's brain: fly alongside `squad_leader` at `offset`.
func start_escort(squad_leader: Enemy, offset: Vector2) -> void:
	if state != State.IN_FORMATION:
		return
	leader = squad_leader
	escort_offset = offset
	aggression = squad_leader.aggression
	_begin_attack(ESCORT_BRAIN)


## The leader is gone: attack on our own.
func release_escort() -> void:
	leader = null
	brain = def.brain
	brain.begin(self)


func _begin_attack(attack_brain: EnemyBrain) -> void:
	state = State.DIVING
	add_to_group(&"attackers")
	brain = attack_brain
	attack_time = 0.0
	fire_cooldown = randf_range(0.2, 0.6)
	aim_facing = false
	brain.begin(self)


func _attack(delta: float) -> void:
	attack_time += delta
	phase_time += delta
	fire_cooldown -= delta
	var done := brain.tick(self, delta) or attack_time > brain.max_time
	var push := Steering.separation(position, _attacker_positions(), SEPARATION_RADIUS) * SEPARATION_FORCE
	position += (velocity + push) * delta
	position.x = clampf(position.x, MIN_X, MAX_X)
	if aim_facing and is_instance_valid(target):
		_face(target.global_position - global_position, delta)
	else:
		_face(velocity, delta)
	if position.y > BOTTOM:
		position = Vector2(position.x, TOP)
		done = done or not brain.continue_after_wrap(self)
	if done:
		_end_attack()


func _end_attack() -> void:
	remove_from_group(&"attackers")
	leader = null
	aim_facing = false
	state = State.RETURNING
	if slot == NO_SLOT:
		remove_from_group(&"enemies")
		queue_free()


func set_phase(value: int) -> void:
	phase = value
	phase_time = 0.0


## Turns toward `direction` at up to `turn_rate` radians per second and moves at `speed`.
func steer(direction: Vector2, speed: float, turn_rate: float, delta: float) -> void:
	velocity = Steering.turn(velocity, direction, turn_rate * delta, speed * _speed_scale())


## Where the player will be in `lead` seconds, kept on screen.
func predicted_player(lead: float) -> Vector2:
	if not is_instance_valid(target):
		return Vector2(270, 860)
	var guess := target.global_position + target.velocity * lead
	return guess.clamp(Vector2(MIN_X, Player.MIN_Y), Vector2(MAX_X, Player.MAX_Y))


## A Shield Warden elite protects this enemy: shots pass through it.
func set_shielded(on: bool) -> void:
	$Hurtbox.invulnerable = on
	_visual.modulate = _tint * Color(0.85, 0.75, 1.3) if on else _tint


## Damage from outside a hitbox (kill blasts).
func damage(amount: int) -> void:
	_health.take_damage(amount)


func is_damaged() -> bool:
	return _health.hp < _health.max_hp


func health() -> Health:
	return _health


## Up to `count` idle formation enemies within `radius`, nearest first (squad recruiting).
func nearby_idle(radius: float, count: int) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var other := node as Enemy
		if other != self and other.state == State.IN_FORMATION and other.position.distance_to(position) <= radius:
			found.append(other)
	found.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.position.distance_squared_to(position) < b.position.distance_squared_to(position))
	return found.slice(0, count)


## Fires one shot at `point`, with random `spread` and a fixed `offset_degrees` (fans).
func fire_at(point: Vector2, spread := 0.0, offset_degrees := 0.0) -> void:
	if not is_instance_valid(target) or not target.alive or global_position.y > target.global_position.y - 60.0:
		return
	var bullet: Bullet = Pools.acquire(ENEMY_BULLET)
	var angle := deg_to_rad(offset_degrees + randf_range(-spread, spread))
	var direction := global_position.direction_to(point).rotated(angle)
	var speed := def.bullet_speed * difficulty.enemy_bullet_speed
	bullet.launch(entities, global_position + direction * 14.0, direction * speed, 1, ENEMY_BULLET)


func _speed_scale() -> float:
	return 1.0 + 0.15 * (aggression - 1.0)


## Built once per physics frame and shared by every diver (was rebuilt by each one: O(n^2) per frame).
## Includes this enemy; Steering.separation skips its own zero-distance entry.
static var _positions_frame := -1
static var _positions: Array[Vector2] = []


func _attacker_positions() -> Array[Vector2]:
	var frame := Engine.get_physics_frames()
	if frame != _positions_frame:
		_positions_frame = frame
		_positions.clear()
		for node in get_tree().get_nodes_in_group(&"attackers"):
			_positions.append((node as Node2D).position)
	return _positions


# --- Entry and formation ---------------------------------------------------------------------

func _advance_path(delta: float) -> void:
	_distance += def.speed * delta
	var length := _path.get_baked_length()
	var previous := position
	position = _path.sample_baked(minf(_distance, length))
	_face(position - previous, delta)
	if _distance >= length:
		if slot == NO_SLOT:
			_leave()
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


func _leave() -> void:
	remove_from_group(&"enemies")
	EventBus.enemy_escaped.emit(self)
	queue_free()


func _on_died() -> void:
	remove_from_group(&"enemies")
	remove_from_group(&"attackers")
	var score := def.dive_score if state == State.DIVING else def.score
	for t in def.all_traits():
		t.killed(self)
	EventBus.enemy_killed.emit(self, global_position, score)
	queue_free()
