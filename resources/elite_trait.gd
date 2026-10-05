class_name EliteTrait
extends Resource
## Behavior that makes an elite unique; an elite or boss phase can carry several. Shared between
## elites, so per-elite state lives in `state(elite)`, one Dictionary per trait per elite.
## Override the hooks you need.


## Settings that wait for something (smaller = harder), so a stronger perk divides them.
const WAITS := ["interval", "delay", "telegraph", "warn", "aim_time", "closed_time", "down_time", "lock_time", "charge_time", "respawn", "regrow", "gap", "stagger", "mark_time", "swing_after", "evolve_time"]
## Settings a stronger perk must not change (a longer window would make the elite easier).
const KEEP := ["mult", "hp_step", "alpha", "solid_time", "open_time", "eye_open", "peek_time", "arc_open", "copy_life", "fragment", "weapon", "lane", "pod_radius"]


## A copy for an elite of a higher level: counts, radii and speeds times `perk`, waits divided by
## it, and hit-point settings (ending in "hp") times `hp`. Settings named in `KEEP` stay put.
func scaled(perk: float, hp: float) -> EliteTrait:
	if is_equal_approx(perk, 1.0) and is_equal_approx(hp, 1.0):
		return self
	var copy: EliteTrait = duplicate()
	for info in get_property_list():
		if not info["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		var key: String = info["name"]
		var value: Variant = get(key)
		if (value is not float and value is not int) or KEEP.any(func(k: String) -> bool: return key.contains(k)):
			continue
		var factor := hp if key.ends_with("hp") else (1.0 / perk if WAITS.any(func(w: String) -> bool: return key.contains(w)) else perk)
		copy.set(key, maxi(1, roundi(value * factor)) if value is int else snappedf(value * factor, 0.01))
	return copy


func state(elite: Elite) -> Dictionary:
	return elite.state.get_or_add(self, {})


func begin(_elite: Elite) -> void:
	pass


func tick(_elite: Elite, _delta: float) -> void:
	pass


## Damage a hit on the elite's own hurtbox actually deals after the trait (armor, shells).
func absorb(_elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	return amount


func end(_elite: Elite) -> void:
	pass


## After `end` when a boss changes phase: frees the visuals this trait hung on the elite and
## forgets its state, so a later phase can begin it fresh.
func clear(elite: Elite) -> void:
	for value: Variant in state(elite).values():
		if value is Node and is_instance_valid(value) and (value as Node).get_parent() == elite:
			(value as Node).queue_free()
	elite.state.erase(self)
