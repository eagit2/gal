class_name Player
extends Node2D
## Player ship: movement (keyboard, gamepad, touch drag), shooting, shield bubble, grazing, invulnerability
## after a hit. Run stats (GameState.stats) modify speed and the weapon; slow-mo doesn't slow the ship.

signal hit

const SPEED := 380.0
const MARGIN := 28.0
const MIN_Y := 70.0  # full screen height, below the HUD row
const MAX_Y := 920.0
const INVULN_TIME := 2.0
## Touch: keep the ship this far above the finger so it stays visible.
const TOUCH_OFFSET := Vector2(0, -90)
const SHIELD_SCENE := preload("res://scenes/player/shield.tscn")
const SECONDARY_SCENE := preload("res://scenes/player/secondary_weapons.tscn")
## Enemy shots passing within this distance (but missing) count as grazes.
const GRAZE_RADIUS := 30.0

@export var weapon: WeaponDef
var entities: Node
var alive := true
## Pixels per second this frame; enemies lead their aim with it.
var velocity := Vector2.ZERO
var shield: Shield
var _cooldown := 0.0
var _invuln := 0.0
var _touch_target: Variant = null
var _graze_candidates: Array[Bullet] = []

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_hurtbox.hurt.connect(_on_hurt)
	# Added from code so player.tscn stays untouched while the art PR is open.
	shield = SHIELD_SCENE.instantiate()
	add_child(shield)
	var secondary: Node2D = SECONDARY_SCENE.instantiate()
	secondary.player = self
	add_child(secondary)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	var stats := GameState.stats
	# Real seconds, so slow-mo (Graze) slows the world but not the ship.
	var real_delta := delta / Engine.time_scale
	var speed: float = SPEED * stats[&"move_speed"]
	var motion := Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed * real_delta
	if _touch_target != null:
		motion = ((_touch_target as Vector2) - position).limit_length(speed * 1.5 * real_delta)
	var before := position
	position = (position + motion).clamp(Vector2(MARGIN, MIN_Y), Vector2(540 - MARGIN, MAX_Y))
	velocity = (position - before) / delta

	_cooldown -= real_delta
	var auto_fire: bool = SaveManager.data["settings"]["auto_fire"]
	if _cooldown <= 0.0 and (Input.is_action_pressed("fire") or auto_fire or _touch_target != null):
		_fire()

	if _invuln > 0.0:
		_invuln -= delta
		_visual.visible = fmod(_invuln, 0.2) < 0.12
		if _invuln <= 0.0:
			_visual.visible = true
	else:
		_check_grazes()
	# The bubble takes hits first; the core is safe while it is up.
	_hurtbox.invulnerable = _invuln > 0.0 or shield.up
	shield.invulnerable = not shield.up or _invuln > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index > 0:
		# A second finger is the special (Cryo Pulse); the first keeps steering.
		if event.pressed:
			EventBus.special_requested.emit()
	elif event is InputEventScreenTouch:
		_touch_target = event.position + TOUCH_OFFSET if event.pressed else null
	elif event is InputEventScreenDrag and event.index == 0:
		_touch_target = event.position + TOUCH_OFFSET
	elif event.is_action_pressed("special"):
		EventBus.special_requested.emit()


func respawn(at: Vector2) -> void:
	position = at
	alive = true
	visible = true
	_touch_target = null
	velocity = Vector2.ZERO
	_invuln = INVULN_TIME
	_hurtbox.invulnerable = true


func _fire() -> void:
	var stats := GameState.stats
	_cooldown = 1.0 / (weapon.fire_rate * stats[&"fire_rate"])
	var count: int = weapon.spread_count + stats[&"extra_shots"]
	var angle: float = weapon.spread_angle + stats[&"spread"]
	for degrees in WeaponDef.fan(count, angle):
		fire_shot(global_position + Vector2(0, -26), degrees)
	EventBus.shot_fired.emit()


## One primary-weapon shot with the current stats (drones use this too).
func fire_shot(from: Vector2, degrees: float) -> void:
	var stats := GameState.stats
	var bullet: Bullet = Pools.acquire(weapon.projectile_scene)
	var shot_velocity: Vector2 = Vector2.UP.rotated(deg_to_rad(degrees)) * weapon.projectile_speed * stats[&"projectile_speed"]
	bullet.launch(entities, from, shot_velocity, weapon.damage + stats[&"damage"], weapon.projectile_scene, stats[&"pierce"], stats[&"homing"])


## A shot counts as a graze once it has come within GRAZE_RADIUS and then leaves it without hitting.
func _check_grazes() -> void:
	var limit := GRAZE_RADIUS * GRAZE_RADIUS
	for node in get_tree().get_nodes_in_group(&"enemy_shots"):
		var bullet := node as Bullet
		if not bullet.grazed and bullet.global_position.distance_squared_to(global_position) < limit:
			bullet.grazed = true
			_graze_candidates.append(bullet)
	for bullet in _graze_candidates.duplicate():
		if not bullet.is_inside_tree() or bullet.spent or not bullet.grazed:
			_graze_candidates.erase(bullet)
		elif bullet.global_position.distance_squared_to(global_position) >= limit:
			_graze_candidates.erase(bullet)
			EventBus.bullet_grazed.emit(bullet.global_position)


func _on_hurt(_hitbox: Hitbox) -> void:
	alive = false
	shield.invulnerable = true
	visible = false
	_hurtbox.invulnerable = true
	hit.emit()
