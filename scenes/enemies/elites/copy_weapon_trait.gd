class_name CopyWeaponTrait
extends EliteTrait
## Fires a copy of your own nose weapon back at you once you have used it a while. Counter: the
## copy has your gun's pattern, so a weapon you know how to dodge is safer.

const ENEMY_BULLET := preload("res://scenes/projectiles/enemy_bullet.tscn")

@export var copy_delay := 2.0
@export var fire_interval := 1.5
@export var damage_mult := 0.7


func begin(elite: Elite) -> void:
	state(elite)["id"] = &""
	state(elite)["held"] = 0.0
	state(elite)["cool"] = 0.0


## Speed of the copy: your shot's speed toned down so it can be dodged.
static func copy_speed(projectile_speed: float) -> float:
	return clampf(projectile_speed * 0.3, 180.0, 380.0)


## Damage of the copy: the weapon's damage times `factor`, at least 1.
static func copy_damage(damage: int, factor: float) -> int:
	return maxi(1, roundi(damage * factor))


func tick(elite: Elite, delta: float) -> void:
	var player := elite.target
	var s := state(elite)
	if not elite.entered or not is_instance_valid(player) or not player.alive or player.weapon == null:
		return
	if s["id"] != player.weapon.id:
		s["id"] = player.weapon.id
		s["held"] = 0.0
	s["held"] += delta
	s["cool"] -= delta
	if s["held"] >= copy_delay and s["cool"] <= 0.0:
		s["cool"] = fire_interval
		_fire_copy(elite, player.weapon)


func _fire_copy(elite: Elite, weapon: WeaponDef) -> void:
	var aim := elite.global_position.direction_to(elite.target.global_position)
	var speed := copy_speed(weapon.projectile_speed) * elite.level.speed * elite.difficulty.enemy_bullet_speed
	var damage := copy_damage(weapon.damage, damage_mult)
	for degrees in weapon.shot_angles():
		var bullet: Bullet = Pools.acquire(ENEMY_BULLET)
		var direction := aim.rotated(deg_to_rad(degrees))
		bullet.launch(elite.entities, elite.global_position + direction * 26.0, direction * speed, damage, ENEMY_BULLET)
