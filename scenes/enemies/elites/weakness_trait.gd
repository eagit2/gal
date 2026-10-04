class_name WeaknessTrait
extends EliteTrait
## Takes extra damage from one weapon type, shown by a weapon-colored badge above it. Counter:
## bring the matching gun from the hangar.

@export var mark_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/weakness_mark.tscn")
@export var weapon := "laser"
@export var mult := 3


func begin(elite: Elite) -> void:
	var mark: Node2D = mark_visual.instantiate()
	mark.position = Vector2(0, -48.0 * elite.def.visual_scale / 1.8)
	mark.call("setup", weapon)
	elite.add_child(mark)
	state(elite)["mark"] = mark


## Damage after the weakness: `factor` times, at least one more than `amount`; nothing stays nothing.
static func boosted(amount: int, factor: int) -> int:
	if amount <= 0:
		return amount
	return maxi(amount + 1, amount * factor)


func absorb(elite: Elite, amount: int, hitbox: Hitbox) -> int:
	var bullet := hitbox as Bullet
	if amount <= 0 or bullet == null or not String(bullet.weapon_id).contains(weapon):
		return amount
	var mark: Variant = state(elite).get("mark")
	if is_instance_valid(mark):
		(mark as Node).call("flash")
	return boosted(amount, mult)
