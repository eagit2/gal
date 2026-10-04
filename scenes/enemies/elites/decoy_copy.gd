class_name DecoyCopy
extends Node2D
## A hologram of the Mirage: translucent, mirrors the real elite's patrol, fires the same fans
## (real danger) and pops in one hit. It casts no shadow.

const FADE := 0.4
const BLEND := 0.6
const CENTER_X := 270.0

var _elite: Elite
var _index := 0
var _life := 6.0
var _age := 0.0
var _fire := 1.0
var _visual: Node2D


func setup(elite: Elite, index: int, life: float) -> void:
	_elite = elite
	_index = index
	_life = life
	position = elite.position
	_fire = elite.def.fire_interval * 0.6


## x of copy `index` for a real elite at `x`: copy 0 mirrors it about the centre, copy 1 follows
## a tent over its patrol, copy 2 the opposite tent (later copies repeat the pattern).
static func copy_x(x: float, index: int, min_x: float, max_x: float) -> float:
	var u := clampf((x - min_x) / (max_x - min_x), 0.0, 1.0)
	match index % 3:
		0:
			u = 1.0 - u
		1:
			u = 1.0 - absf(2.0 * u - 1.0)
		_:
			u = absf(2.0 * u - 1.0)
	return lerpf(min_x, max_x, u)


func _ready() -> void:
	_visual = _elite.def.visual_scene.instantiate()
	_visual.scale = Vector2.ONE * _elite.def.visual_scale
	add_child(_visual)
	$Health.died.connect(queue_free)


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	_age += delta
	if not is_instance_valid(_elite) or _age >= _life:
		queue_free()
		return
	var goal := Vector2(copy_x(_elite.position.x, _index, Elite.MIN_X, Elite.MAX_X), _elite.position.y)
	position = goal if _age >= BLEND else position.lerp(goal, minf(1.0, delta * 8.0))
	var left := _life - _age
	var flicker := 0.5 + 0.08 * sin(_age * 30.0)
	modulate = Color(0.5, 1.2, 1.4, flicker * clampf(minf(_age / FADE, left / FADE), 0.0, 1.0))
	_fire -= delta
	if _fire <= 0.0 and _elite.entered and _elite.can_fire:
		_fire = _elite.def.fire_interval * _elite.fire_scale
		_fire_fan()


func _fire_fan() -> void:
	var target := _elite.target
	if not is_instance_valid(target) or not target.alive:
		return
	var aim := global_position.direction_to(target.global_position)
	var shots := _elite.def.fan_shots
	for i in shots:
		var direction := aim.rotated((i - (shots - 1) / 2.0) * 0.22)
		var bullet: Bullet = Pools.acquire(Elite.ENEMY_BULLET)
		var speed := _elite.def.bullet_speed * _elite.level.speed * _elite.difficulty.enemy_bullet_speed
		bullet.launch(_elite.entities, global_position + direction * 26.0, direction * speed, maxi(1, roundi(_elite.level.damage)), Elite.ENEMY_BULLET)
