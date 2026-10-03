class_name ScrapBall
extends Bullet
## Scrap Cannon shot: a big slow lump of scrap that hits hard, then breaks into `shrapnel` small
## pieces flying out from where it hit (they skip the enemy it hit).

const SHRAPNEL_SCENE := preload("res://scenes/projectiles/shrapnel.tscn")
const SHRAPNEL_SPEED := 560.0
const SHRAPNEL_DAMAGE := 1
const SHRAPNEL_RANGE := 150.0
const SPIN := 3.0

## Pieces this ball breaks into (WeaponDef.shrapnel + the shrapnel stat).
var shrapnel := 0


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	shrapnel = weapon.shrapnel + int(stats[&"shrapnel"])
	rotation = randf() * TAU


func _physics_process(delta: float) -> void:
	super(delta)
	rotation += SPIN * delta


## Directions (degrees from straight up) of `count` pieces, evenly around a full circle.
static func shrapnel_angles(count: int) -> Array[float]:
	var angles: Array[float] = []
	for i in maxi(count, 0):
		angles.append(360.0 * i / count)
	return angles


func _on_hit(hurtbox: Hurtbox) -> void:
	var parent := get_parent()
	var struck := hurtbox.get_parent()
	if parent and shrapnel > 0:
		# Deferred: new hitboxes can't join the physics world mid-collision callback.
		_burst.call_deferred(parent, global_position, struck, shrapnel, randf_range(0.0, 60.0))
	super(hurtbox)


func _burst(parent: Node, at: Vector2, struck: Node, count: int, turn: float) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	for degrees in shrapnel_angles(count):
		var piece: Shrapnel = Pools.acquire(SHRAPNEL_SCENE)
		var vel := Vector2.UP.rotated(deg_to_rad(degrees + turn)) * SHRAPNEL_SPEED
		piece.launch(parent, at, vel, SHRAPNEL_DAMAGE, SHRAPNEL_SCENE)
		piece.max_range = SHRAPNEL_RANGE
		piece.ignore = struck if is_instance_valid(struck) else null
