class_name PlayerMine
extends Bullet
## Mine Launcher shot: flies DROP_DISTANCE ahead of the ship, then holds that spot on screen. An
## enemy, or an enemy shot, touching it sets it off: a blast that damages every enemy and elite
## within blast_radius, clears enemy shots there and sets off enemy mines. Goes off by itself after
## LIFETIME. The launcher caps how many are out (WeaponDef.active_cap + the max_active stat).

const DROP_DISTANCE := 120.0
const LIFETIME := 7.0
## Enemy shots this close set it off (they can't be detected as areas).
const TRIGGER_RADIUS := 16.0
const BURST_TIME := 0.35

var blast_radius := 90.0
var _blast_damage := 1
var _moved := 0.0
var _age := 0.0
var _exploded := false


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	blast_radius = weapon.blast_radius + float(stats[&"blast_radius"])
	_blast_damage = damage
	damage = 0  # Touching does nothing; the blast deals the damage.
	_moved = 0.0
	_age = 0.0
	_exploded = false
	rotation = 0.0
	monitoring = true
	$Visual.call(&"arm")


## Whether `point` is inside a blast of `radius` at `center`.
static func in_blast(center: Vector2, point: Vector2, radius: float) -> bool:
	return center.distance_squared_to(point) <= radius * radius


func _physics_process(delta: float) -> void:
	if not _active or _exploded:
		return
	_age += delta
	if _moved < DROP_DISTANCE:
		var step := velocity * delta
		position += step
		_moved += step.length()
	if _age >= LIFETIME or _shot_touching():
		explode()


func _shot_touching() -> bool:
	for node in get_tree().get_nodes_in_group(&"enemy_shots"):
		if in_blast(global_position, (node as Node2D).global_position, TRIGGER_RADIUS):
			return true
	return false


func _on_hit(_hurtbox: Hurtbox) -> void:
	explode()


func explode() -> void:
	if _exploded or not _active:
		return
	_exploded = true
	leave_cap_group()
	set_deferred(&"monitoring", false)
	$Visual.call(&"burst", blast_radius)
	_blast.call_deferred()
	get_tree().create_timer(BURST_TIME, false).timeout.connect(release)


func _blast() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var at := global_position
	for node in tree.get_nodes_in_group(&"enemies"):
		if in_blast(at, (node as Node2D).global_position, blast_radius):
			(node as Enemy).damage(_blast_damage)
	for node in tree.get_nodes_in_group(&"elites"):
		if in_blast(at, (node as Node2D).global_position, blast_radius):
			(node as Elite).damage(_blast_damage)
	for node in tree.get_nodes_in_group(&"enemy_shots"):
		if in_blast(at, (node as Node2D).global_position, blast_radius):
			(node as Bullet).release()
	for node in tree.get_nodes_in_group(&"mines"):
		if in_blast(at, (node as Node2D).global_position, blast_radius):
			(node as Mine).explode()
