class_name BubbleShot
extends Bullet
## Bubble Blower shot: a slow, wobbly bubble (sized by the shot_size stat). A regular enemy it
## touches gets trapped (BubbleTrap): it stops acting, floats up inside the bubble and after a
## moment pops for POP_MULT times the shot's damage. Elites, plated enemies and anything else just
## pop it for its normal, small damage.

const POP_MULT := 4
const WOBBLE_SPEED := 70.0
const WOBBLE_RATE := 5.0

var _t := 0.0


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	scale = Vector2.ONE * float(stats[&"shot_size"])
	rotation = 0.0
	_t = randf() * TAU


## Whether a bubble traps what it hit: only a regular enemy not already in a bubble.
static func traps(is_enemy: bool, plated: bool, already_trapped: bool) -> bool:
	return is_enemy and not plated and not already_trapped


func _physics_process(delta: float) -> void:
	_t += delta
	position.x += sin(_t * WOBBLE_RATE) * WOBBLE_SPEED * delta
	super(delta)


func _on_hit(hurtbox: Hurtbox) -> void:
	var enemy := hurtbox.get_parent() as Enemy
	var plated := enemy != null and (enemy.def.trait_logic is PlateTrait or hurtbox.name != &"Hurtbox")
	var trapped := enemy != null and enemy.has_node(NodePath(BubbleTrap.NODE_NAME))
	if traps(enemy != null, plated, trapped) and enemy.health().hp > 0:
		var trap := BubbleTrap.new()
		trap.name = BubbleTrap.NODE_NAME
		trap.pop_damage = damage * POP_MULT
		trap.size = scale.x
		enemy.add_child.call_deferred(trap)
	super(hurtbox)
