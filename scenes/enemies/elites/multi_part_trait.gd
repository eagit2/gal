class_name MultiPartTrait
extends EliteTrait
## Wears cannons that can be shot off; the core takes no damage until all are gone, and every lost
## cannon speeds up the rest and gives the core a new attack. Counter: pick which cannon to break first.

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")
const PART_SCENE := preload("res://scenes/enemies/elites/cannon_part.tscn")
const SPACING := 46.0

@export var parts := 3
@export var part_hp := 40
@export var core_hp_mult := 1.0
@export var fan_interval := 1.8
@export var stream_interval := 0.45
@export var ring_interval := 3.0
@export var shot_speed := 210.0
## Core attack periods: spiral (1 cannon lost), ring (2 lost), aimed burst (3+ lost).
@export var spiral_interval := 0.3
@export var core_ring_interval := 3.4
@export var burst_interval := 1.4


## Fire-rate multiplier for the surviving cannons after `lost` are gone.
static func rate_for(lost: int) -> float:
	return 1.0 + 0.4 * lost


## Local position of cannon `i` of `n` around the elite.
static func part_offset(i: int, n: int) -> Vector2:
	var x := (i - (n - 1) / 2.0) * SPACING
	return Vector2(x, 12.0 + absf(x) * 0.12)


func begin(elite: Elite) -> void:
	var st := state(elite)
	var list: Array[CannonPart] = []
	st["parts"] = list
	st["core"] = [0.0, 0.0, 0.0, 0.0]  # spiral, ring, burst cooldowns; spiral angle
	for i in parts:
		var part: CannonPart = PART_SCENE.instantiate()
		part.kind = i % 3
		part.hp = maxi(1, roundi(part_hp * elite.difficulty.enemy_hp))
		part.cooldown = 1.0 + 0.5 * i
		part.position = part_offset(i, parts)
		part.destroyed.connect(func() -> void: EventBus.elite_trait_broken.emit(part.global_position))
		list.append(part)
		elite.add_child(part)


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var list: Array[CannonPart] = state(elite)["parts"]
	var alive := list.filter(func(p: CannonPart) -> bool: return is_instance_valid(p) and not p.is_queued_for_deletion())
	var lost := list.size() - alive.size()
	var rate := rate_for(lost)
	for part: CannonPart in alive:
		part.cooldown -= delta * rate
		part.set_charge(part.cooldown < 0.3)
		if part.cooldown <= 0.0:
			_fire_part(elite, part)
	if lost > 0:
		_fire_core(elite, lost, delta)


func absorb(elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	var list: Array[CannonPart] = state(elite)["parts"]
	if list.any(func(p: CannonPart) -> bool: return is_instance_valid(p) and not p.is_queued_for_deletion()):
		return 0
	return maxi(1, roundi(amount * core_hp_mult))


func end(elite: Elite) -> void:
	var list: Array = state(elite).get("parts", [])
	for part: Variant in list:
		if is_instance_valid(part):
			(part as Node).queue_free()
	list.clear()


## Cannon 0 fires an aimed fan, 1 a straight stream, 2 a slow ring.
func _fire_part(elite: Elite, part: CannonPart) -> void:
	var from := part.global_position
	match part.kind:
		0:
			part.cooldown = fan_interval
			var aim := _aim(elite, from)
			for k in 3:
				_shoot(elite, from, aim.rotated((k - 1) * 0.24), shot_speed)
		1:
			part.cooldown = stream_interval
			_shoot(elite, from, Vector2.DOWN, shot_speed * 1.15)
		_:
			part.cooldown = ring_interval
			_ring(elite, from, 8, 0.0, shot_speed * 0.6)


func _fire_core(elite: Elite, lost: int, delta: float) -> void:
	var core: Array = state(elite)["core"]
	var from := elite.global_position
	core[0] -= delta
	if core[0] <= 0.0:
		core[0] = spiral_interval
		core[3] += 0.55
		_shoot(elite, from, Vector2.from_angle(core[3]), shot_speed * 0.8)
	if lost >= 2:
		core[1] -= delta
		if core[1] <= 0.0:
			core[1] = core_ring_interval
			_ring(elite, from, 10, core[3], shot_speed * 0.7)
	if lost >= 3:
		core[2] -= delta
		if core[2] <= 0.0:
			core[2] = burst_interval
			var aim := _aim(elite, from)
			for k in 5:
				_shoot(elite, from, aim.rotated((k - 2) * 0.12), shot_speed * 1.2)


func _aim(elite: Elite, from: Vector2) -> Vector2:
	if is_instance_valid(elite.target):
		return from.direction_to(elite.target.global_position)
	return Vector2.DOWN


func _ring(elite: Elite, from: Vector2, count: int, offset: float, speed: float) -> void:
	for k in count:
		_shoot(elite, from, Vector2.from_angle(offset + TAU * k / count), speed)


func _shoot(elite: Elite, from: Vector2, direction: Vector2, speed: float) -> void:
	var bullet: Bullet = Pools.acquire(ENEMY_BULLET)
	var velocity := direction * speed * elite.level.speed * elite.difficulty.enemy_bullet_speed
	bullet.launch(elite.entities, from + direction * 14.0, velocity, maxi(1, roundi(elite.level.damage)), ENEMY_BULLET)
