class_name Enemy
extends Node2D
## Formation enemy for M1: sways around its home slot and fires at the player.
## Entry paths and dives arrive in M2.

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
const SWAY := Vector2(40, 4)

var def: EnemyDef
var home := Vector2.ZERO
var target: Node2D
var entities: Node
var difficulty: DifficultyDef
## Multiplies fire rate; rises with each wave.
var aggression := 1.0
var _t := 0.0
var _fire_timer := 0.0

@onready var _health: Health = $Health


func setup(enemy_def: EnemyDef, home_pos: Vector2, diff: DifficultyDef) -> void:
	def = enemy_def
	home = home_pos
	difficulty = diff
	position = home_pos


func _ready() -> void:
	add_to_group(&"enemies")
	_health.reset(maxi(1, roundi(def.hp * difficulty.enemy_hp)))
	_health.died.connect(_on_died)
	$Visual.modulate = def.color
	_fire_timer = _next_fire_delay() + randf() * 2.0


func _physics_process(delta: float) -> void:
	_t += delta
	position = home + Vector2(sin(_t * 1.1) * SWAY.x, sin(_t * 2.0 + home.x * 0.05) * SWAY.y)
	if def.fire_interval <= 0.0:
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = _next_fire_delay()
		_fire()


func _next_fire_delay() -> float:
	return def.fire_interval * randf_range(0.6, 1.4) / (difficulty.dive_frequency * aggression)


func _fire() -> void:
	if not is_instance_valid(target) or not (target as Player).alive:
		return
	var bullet: Bullet = Pools.acquire(ENEMY_BULLET)
	var direction := global_position.direction_to(target.global_position)
	var speed := def.bullet_speed * difficulty.enemy_bullet_speed
	bullet.launch(entities, global_position + Vector2(0, 14), direction * speed, 1, ENEMY_BULLET)


func _on_died() -> void:
	remove_from_group(&"enemies")
	EventBus.enemy_killed.emit(self, global_position, def.score)
	queue_free()
