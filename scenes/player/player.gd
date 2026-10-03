class_name Player
extends Node2D
## Player ship: movement (keyboard, gamepad, touch drag), shooting, shield bubble, invulnerability after a hit.

signal hit

const SPEED := 380.0
const MARGIN := 28.0
const MIN_Y := 70.0  # full screen height, below the HUD row
const MAX_Y := 920.0
const INVULN_TIME := 2.0
## Touch: keep the ship this far above the finger so it stays visible.
const TOUCH_OFFSET := Vector2(0, -90)
const SHIELD_SCENE := preload("res://scenes/player/shield.tscn")

@export var weapon: WeaponDef
var entities: Node
var alive := true
## Pixels per second this frame; enemies lead their aim with it.
var velocity := Vector2.ZERO
var shield: Shield
var _cooldown := 0.0
var _invuln := 0.0
var _touch_target: Variant = null

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_hurtbox.hurt.connect(_on_hurt)
	# Added from code so player.tscn stays untouched while the art PR is open.
	shield = SHIELD_SCENE.instantiate()
	add_child(shield)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	var motion := Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED * delta
	if _touch_target != null:
		motion = ((_touch_target as Vector2) - position).limit_length(SPEED * 1.5 * delta)
	var before := position
	position = (position + motion).clamp(Vector2(MARGIN, MIN_Y), Vector2(540 - MARGIN, MAX_Y))
	velocity = (position - before) / delta

	_cooldown -= delta
	var auto_fire: bool = SaveManager.data["settings"]["auto_fire"]
	if _cooldown <= 0.0 and (Input.is_action_pressed("fire") or auto_fire or _touch_target != null):
		_fire()

	if _invuln > 0.0:
		_invuln -= delta
		_visual.visible = fmod(_invuln, 0.2) < 0.12
		if _invuln <= 0.0:
			_visual.visible = true
	# The bubble takes hits first; the core is safe while it is up.
	_hurtbox.invulnerable = _invuln > 0.0 or shield.up
	shield.invulnerable = not shield.up or _invuln > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_target = event.position + TOUCH_OFFSET if event.pressed else null
	elif event is InputEventScreenDrag:
		_touch_target = event.position + TOUCH_OFFSET


func respawn(at: Vector2) -> void:
	position = at
	alive = true
	visible = true
	_touch_target = null
	velocity = Vector2.ZERO
	_invuln = INVULN_TIME
	_hurtbox.invulnerable = true


func _fire() -> void:
	_cooldown = 1.0 / weapon.fire_rate
	for angle in weapon.shot_angles():
		var bullet: Bullet = Pools.acquire(weapon.projectile_scene)
		var velocity := Vector2.UP.rotated(deg_to_rad(angle)) * weapon.projectile_speed
		bullet.launch(entities, global_position + Vector2(0, -26), velocity, weapon.damage, weapon.projectile_scene)
	EventBus.shot_fired.emit()


func _on_hurt(_hitbox: Hitbox) -> void:
	alive = false
	shield.invulnerable = true
	visible = false
	_hurtbox.invulnerable = true
	hit.emit()
