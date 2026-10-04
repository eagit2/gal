class_name BubbleShot
extends Bullet
## Bubble Blower shot: a slow, wobbly bubble (sized by the shot_size stat, so a bigger bubble is a
## wider trap). Each regular enemy it touches gets trapped in a bubble of its own (BubbleTrap): it
## stops acting, floats up and after a moment pops for POP_MULT times the shot's damage. The shot
## keeps going until it has trapped MAX_TRAPS enemies, passing over ones already in a bubble.
## Elites, plated enemies and anything else just pop it for its normal, small damage.

const POP_MULT := 4
const MAX_TRAPS := 3
const WOBBLE_SPEED := 70.0
const WOBBLE_RATE := 5.0

var _t := 0.0
var _traps_left := MAX_TRAPS


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	scale = Vector2.ONE * float(stats[&"shot_size"])
	rotation = 0.0
	_t = randf() * TAU
	_traps_left = MAX_TRAPS


## Whether a bubble traps what it hit: only a regular enemy not already in a bubble.
static func traps(is_enemy: bool, plated: bool, already_trapped: bool) -> bool:
	return is_enemy and not plated and not already_trapped


## Whether a bubble that just trapped an enemy, with `left` traps left before it, keeps going.
static func keeps_going(left: int) -> bool:
	return left - 1 > 0


func _physics_process(delta: float) -> void:
	_t += delta
	position.x += sin(_t * WOBBLE_RATE) * WOBBLE_SPEED * delta
	super(delta)


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() != null and area.get_parent().has_node(NodePath(BubbleTrap.NODE_NAME)):
		return  # Already in a bubble: float past it.
	super(area)


func _on_hit(hurtbox: Hurtbox) -> void:
	var enemy := hurtbox.get_parent() as Enemy
	var plated := enemy != null and (enemy.def.all_traits().any(func(t: EnemyTrait) -> bool: return t is PlateTrait) or hurtbox.name != &"Hurtbox")
	var trapped := enemy != null and enemy.has_node(NodePath(BubbleTrap.NODE_NAME))
	if traps(enemy != null, plated, trapped) and enemy.health().hp > 0:
		var trap := BubbleTrap.new()
		trap.name = BubbleTrap.NODE_NAME
		trap.pop_damage = damage * POP_MULT
		trap.size = scale.x
		enemy.add_child.call_deferred(trap)
		if keeps_going(_traps_left):
			_traps_left -= 1
			StatusEffects.apply_hit(enemy, burn, chill, chain)
			if reports_miss:
				EventBus.shot_hit.emit()
			spent = false
			return
	super(hurtbox)
