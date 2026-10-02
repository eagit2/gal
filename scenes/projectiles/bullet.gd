class_name Bullet
extends Hitbox
## Pooled straight-line projectile. Returns to the pool on hit or when off screen.

const BOUNDS := Rect2(-40, -40, 620, 1040)

## Player shots report misses (used by combo tracking).
@export var reports_miss := false
var velocity := Vector2.ZERO
var _pool_scene: PackedScene
var _active := false


func _ready() -> void:
	super()
	single_hit = true
	hit.connect(func(_h: Hurtbox) -> void: release())


func launch(parent: Node, from: Vector2, vel: Vector2, dmg: int, pool_scene: PackedScene) -> void:
	_pool_scene = pool_scene
	velocity = vel
	damage = dmg
	spent = false
	_active = true
	rotation = vel.angle() + PI / 2
	parent.add_child(self)
	global_position = from


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if _active and not BOUNDS.has_point(position):
		if reports_miss:
			EventBus.shot_missed.emit()
		release()


func release() -> void:
	if not _active:
		return
	_active = false
	Pools.release.call_deferred(_pool_scene, self)
