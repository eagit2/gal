class_name Player
extends Node2D
## Player ship: movement (keyboard, gamepad, touch drag), shooting every fitted gun, the shield bubble
## (only with a shield part fitted), grazing, invulnerability after a hit.
## Run stats (GameState.stats) modify speed and every weapon; slow-mo doesn't slow the ship.

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
const PILOT_POWER := preload("res://scenes/player/pilot_power.gd")
const WINGMAN_SCENE := preload("res://scenes/player/wingman.tscn")
## Where the rescued wingman flies, relative to the ship (dual fighter).
const WINGMAN_OFFSET := Vector2(38, 0)
const CAPTURE_TIME := 1.1
## Enemy shots passing within this distance (but missing) count as grazes.
const GRAZE_RADIUS := 30.0

## The nose weapon (drones copy it); set from the hangar loadout on ready.
@export var weapon: WeaponDef
var entities: Node
var alive := true
## Dual fighter: a rescued wingman flies alongside, doubling fire. A hit takes the wingman instead
## of a life.
var dual := false
var _wingman: Node2D
## Pixels per second this frame; enemies lead their aim with it.
var velocity := Vector2.ZERO
var shield: Shield
## Every gun on the ship: {"mount", "weapon", "cooldown"} (ShipGuns).
var _guns: Array[Dictionary] = []
var _invuln := 0.0
var _touch_target: Variant = null
var _graze_candidates: Array[Bullet] = []

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_hurtbox.hurt.connect(_on_hurt)
	_guns = ShipGuns.mounted(Hangar.CATALOG, Hangar.state())
	for gun in _guns:
		gun["cooldown"] = 0.0
	weapon = _guns[0]["weapon"]
	# Added from code so player.tscn stays untouched while the art PR is open.
	shield = SHIELD_SCENE.instantiate()
	add_child(shield)
	var secondary: Node2D = SECONDARY_SCENE.instantiate()
	secondary.player = self
	add_child(secondary)
	var power: Node = PILOT_POWER.new()
	power.set("player", self)
	add_child(power)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	var stats := GameState.stats
	# Real seconds, so slow-mo (Graze) slows the world but not the ship.
	var real_delta := delta / Engine.time_scale
	var speed: float = SPEED * stats[&"move_speed"]
	var motion := Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed * real_delta
	# Engine placement: faster strafing away from the side the engine sits on.
	var strafe: float = stats[&"strafe_left"] if motion.x < 0.0 else stats[&"strafe_right"]
	motion.x *= strafe
	if _touch_target != null:
		var to_target := (_touch_target as Vector2) - position
		strafe = stats[&"strafe_left"] if to_target.x < 0.0 else stats[&"strafe_right"]
		motion = to_target.limit_length(speed * 1.5 * real_delta * strafe)
	var before := position
	var max_x := 540 - MARGIN - (WINGMAN_OFFSET.x if dual else 0.0)
	position = (position + motion).clamp(Vector2(MARGIN, MIN_Y), Vector2(max_x, MAX_Y))
	velocity = (position - before) / delta

	var auto_fire: bool = SaveManager.data["settings"]["auto_fire"]
	var firing := Input.is_action_pressed("fire") or auto_fire or _touch_target != null
	for gun in _guns:
		gun["cooldown"] -= real_delta
		if firing and gun["cooldown"] <= 0.0:
			_fire(gun)

	if _invuln > 0.0:
		_invuln -= delta
		_visual.visible = fmod(_invuln, 0.2) < 0.12
		if _invuln <= 0.0:
			_visual.visible = true
	else:
		_check_grazes()
	# The bubble takes hits first; the core is safe while it is up.
	_hurtbox.invulnerable = _invuln > 0.0 or shield.up
	if dual:
		(_wingman.get_node("Hurtbox") as Hurtbox).invulnerable = _invuln > 0.0
	shield.invulnerable = not shield.up or _invuln > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index > 0:
		return  # Only the first finger steers.
	if event is InputEventScreenTouch:
		_touch_target = event.position + TOUCH_OFFSET if event.pressed else null
	elif event is InputEventScreenDrag and event.index == 0:
		_touch_target = event.position + TOUCH_OFFSET


## Pilot powers: no damage for `seconds` (keeps the longer of this and any current window).
func grant_invulnerability(seconds: float) -> void:
	_invuln = maxf(_invuln, seconds)


## A copy of the ship's look (with its hangar parts), for the captured ship and the wingman.
func make_ship_copy() -> Node2D:
	var copy := _visual.duplicate() as Node2D
	copy.visible = true
	return copy


func set_dual(on: bool) -> void:
	if on == dual:
		return
	dual = on
	if on:
		_wingman = WINGMAN_SCENE.instantiate()
		_wingman.position = WINGMAN_OFFSET
		_wingman.add_child(make_ship_copy())
		add_child(_wingman)
		(_wingman.get_node("Hurtbox") as Hurtbox).hurt.connect(func(_h: Hitbox) -> void: _lose_wingman())
		_invuln = maxf(_invuln, 1.5)
	elif is_instance_valid(_wingman):
		_wingman.queue_free()


## Pulled up into a tractor beam: drift to the captor and vanish (the game takes the life).
func capture(captor: Node2D) -> void:
	alive = false
	_hurtbox.invulnerable = true
	shield.invulnerable = true
	_touch_target = null
	var tween := create_tween()
	tween.tween_property(self, "global_position", captor.global_position + Vector2(0, 30), CAPTURE_TIME)
	tween.tween_callback(func() -> void: visible = false)


func _lose_wingman() -> void:
	if not dual:
		return
	EventBus.wingman_lost.emit(_wingman.global_position)
	set_dual(false)
	_invuln = maxf(_invuln, 1.0)


func respawn(at: Vector2) -> void:
	position = at
	alive = true
	visible = true
	_touch_target = null
	velocity = Vector2.ZERO
	_invuln = INVULN_TIME
	_hurtbox.invulnerable = true


## Fires one gun: its WeaponDef from its mount (side guns angle outward), modified by run stats.
func _fire(gun: Dictionary) -> void:
	var stats := GameState.stats
	var gun_weapon: WeaponDef = gun["weapon"]
	var mount: StringName = gun["mount"]
	gun["cooldown"] = 1.0 / (gun_weapon.fire_rate * stats[&"fire_rate"])
	var count: int = gun_weapon.spread_count + stats[&"extra_shots"]
	var angles := WeaponDef.fan(count, gun_weapon.spread_angle + stats[&"spread"])
	var offsets := WeaponDef.barrels(count, gun_weapon.spacing)
	var facing := ShipGuns.muzzle_angle(mount)
	var muzzle := ShipGuns.muzzle_offset(mount)
	for i in angles.size():
		var from := muzzle + Vector2(offsets[i], 0).rotated(deg_to_rad(facing))
		fire_shot(global_position + from, facing + angles[i], gun_weapon)
		if dual:
			fire_shot(global_position + WINGMAN_OFFSET + from, facing + angles[i], gun_weapon)
	if mount == &"nose":
		EventBus.shot_fired.emit()


## One shot of `shot_weapon` (the nose weapon by default) with the current stats (drones use this too).
func fire_shot(from: Vector2, degrees: float, shot_weapon: WeaponDef = null) -> void:
	var stats := GameState.stats
	var w := shot_weapon if shot_weapon else weapon
	var bullet: Bullet = Pools.acquire(w.projectile_scene)
	var shot_velocity: Vector2 = Vector2.UP.rotated(deg_to_rad(degrees)) * w.projectile_speed * stats[&"projectile_speed"]
	bullet.launch(entities, from, shot_velocity, w.damage + stats[&"damage"], w.projectile_scene, w.pierce + stats[&"pierce"], w.homing + stats[&"homing"])
	bullet.burn = stats[&"burn"]
	bullet.chill = stats[&"chill"]
	bullet.chain = stats[&"chain"]


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
	if dual:
		_lose_wingman()
		return
	alive = false
	shield.invulnerable = true
	visible = false
	_hurtbox.invulnerable = true
	hit.emit()
