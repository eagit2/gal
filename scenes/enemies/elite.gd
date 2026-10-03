class_name Elite
extends Node2D
## An elite enemy (EliteDef): flies in from the top, patrols the upper screen, fires fans at the
## player, and runs its trait. Lives in the "elites" group, so formation logic ignores it while the
## stage waits for it. Ramming it costs a life and deals RAM_DAMAGE.

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
const ENTER_SPEED := 160.0
const PATROL_Y := 370.0
const MIN_X := 70.0
const MAX_X := 470.0
const RAM_DAMAGE := 10

var def: EliteDef
var difficulty: DifficultyDef
var target: Player
var entities: Node2D
## Per-elite trait state, read and written by the EliteTrait.
var state := {}
var entered := false
## Multiplies the fire interval (traits speed it up).
var fire_scale := 1.0
var _dir := 1.0
var _t := randf() * TAU
var _fire := 1.5
var _visual: Node2D

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox


func setup(elite_def: EliteDef, diff: DifficultyDef, player: Player, parent: Node2D) -> void:
	def = elite_def
	difficulty = diff
	target = player
	entities = parent
	position = Vector2(randf_range(MIN_X + 60.0, MAX_X - 60.0), -60.0)


func _ready() -> void:
	add_to_group(&"elites")
	_visual = def.visual_scene.instantiate()
	_visual.name = "Visual"
	_visual.scale = Vector2.ONE * def.visual_scale
	_visual.modulate = def.tint
	add_child(_visual)
	health.reset(maxi(1, roundi(def.hp * difficulty.enemy_hp)))
	health.died.connect(_on_died)
	hurtbox.hurt.connect(func(hitbox: Hitbox) -> void: health.take_damage(def.trait_logic.absorb(self, hitbox.damage, hitbox)))
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: health.take_damage(RAM_DAMAGE))
	def.trait_logic.begin(self)
	EventBus.elite_spawned.emit(def)


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	_t += delta
	if not entered:
		position.y += ENTER_SPEED * delta
		entered = position.y >= PATROL_Y
	else:
		position.x += _dir * def.speed * delta
		if position.x > MAX_X or position.x < MIN_X:
			_dir = -_dir
			position.x = clampf(position.x, MIN_X, MAX_X)
		position.y = PATROL_Y + sin(_t * 0.9) * 26.0
		_fire -= delta
		if _fire <= 0.0:
			_fire = def.fire_interval * fire_scale
			fire_fan()
	def.trait_logic.tick(self, delta)


## A fan of `def.fan_shots` aimed at the player.
func fire_fan() -> void:
	if not is_instance_valid(target) or not target.alive:
		return
	var aim := global_position.direction_to(target.global_position)
	for i in def.fan_shots:
		var offset := (i - (def.fan_shots - 1) / 2.0) * 0.22
		fire(aim.rotated(offset), def.bullet_speed)


func fire(direction: Vector2, speed: float) -> void:
	var bullet: Bullet = Pools.acquire(ENEMY_BULLET)
	bullet.launch(entities, global_position + direction * 26.0, direction * speed * difficulty.enemy_bullet_speed, 1, ENEMY_BULLET)


## Damage from outside a hitbox (kill blasts, pilot powers).
func damage(amount: int) -> void:
	health.take_damage(amount)


func _on_died() -> void:
	remove_from_group(&"elites")
	def.trait_logic.end(self)
	EventBus.enemy_killed.emit(self, global_position, def.score)
	EventBus.elite_killed.emit(def, global_position)
	queue_free()
