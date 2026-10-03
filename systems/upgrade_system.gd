class_name UpgradeSystem
extends RefCounted
## Turns owned upgrades (plus synergies and an active combo) into run stats, and rolls card choices
## and drops. Pure functions so tests can call them directly.

## Every stat an effect can change, with its value when nothing is owned.
const BASE_STATS := {
	&"fire_rate": 1.0,  # multiplier
	&"extra_shots": 0,
	&"spread": 0.0,  # extra fan degrees
	&"damage": 0,  # added to the weapon's damage
	&"pierce": 0,  # enemies a shot passes through
	&"homing": 0.0,  # shot turn rate, radians per second
	&"projectile_speed": 1.0,
	&"missiles": 0,
	&"missile_rate": 1.0,
	&"drones": 0,
	&"move_speed": 1.0,
	&"shield_recharge": 1.0,  # multiplier on recharge time (lower is faster)
	&"shield_layers": 0,
	&"magnet": 0.0,  # pickup pull radius
	&"score_mult": 1.0,
	&"drop_mult": 1.0,
	&"overdrive_window": 1.0,
	&"graze_gain": 1.0,
	&"chain_gain": 1.0,
	&"explode_radius": 0.0,  # kills damage enemies within this radius
	&"time_scale": 1.0,
	&"graze_score": 0,
	&"freeze_charges": 0,  # Cryo Pulse uses per stage
	&"freeze_time": 3.0,  # seconds enemies stay frozen
	&"credit_mult": 1.0,  # hangar credits earned this run
}
## Effects on these stats happen once when the upgrade is gained instead of being a stat.
const INSTANT_STATS: Array[StringName] = [&"lives"]


static func compute(owned: Array[UpgradeDef], synergies: Array, extra_effects: Array[Dictionary] = []) -> Dictionary:
	var stats := BASE_STATS.duplicate()
	var tags: Array[StringName] = []
	for upgrade in owned:
		_apply(stats, upgrade.effects)
		for tag in upgrade.tags:
			if tag not in tags:
				tags.append(tag)
	for synergy in active_synergies(tags, synergies):
		_apply(stats, synergy.effects)
	_apply(stats, extra_effects)
	return stats


static func active_synergies(tags: Array[StringName], synergies: Array) -> Array[SynergyDef]:
	var active: Array[SynergyDef] = []
	for synergy in synergies:
		if synergy.required_tags.all(func(tag: StringName) -> bool: return tag in tags):
			active.append(synergy)
	return active


static func _apply(stats: Dictionary, effects: Array[Dictionary]) -> void:
	for effect in effects:
		var stat: StringName = effect["stat"]
		if stat in INSTANT_STATS or not stats.has(stat):
			continue
		match StringName(effect["op"]):
			&"add":
				stats[stat] += effect["value"]
			&"mul":
				stats[stat] *= effect["value"]
			&"max":
				stats[stat] = maxf(stats[stat], effect["value"])


static func stacks(owned: Array[UpgradeDef], id: StringName) -> int:
	return owned.filter(func(u: UpgradeDef) -> bool: return u.id == id).size()


## Upgrades from `source` that can still be offered: below max stacks with requirements owned.
static func available(pool: UpgradePool, owned: Array[UpgradeDef], source := UpgradeDef.Source.CARD) -> Array[UpgradeDef]:
	var ids: Array[StringName] = []
	for upgrade in owned:
		ids.append(upgrade.id)
	var result: Array[UpgradeDef] = []
	for upgrade in pool.upgrades:
		if upgrade.source == source and stacks(owned, upgrade.id) < upgrade.max_stacks and upgrade.requires.all(func(r: StringName) -> bool: return r in ids):
			result.append(upgrade)
	return result


## `count` distinct card upgrades, weighted by rarity.
static func roll_choices(pool: UpgradePool, owned: Array[UpgradeDef], count: int, rng: RandomNumberGenerator) -> Array[UpgradeDef]:
	var candidates := available(pool, owned)
	var picked: Array[UpgradeDef] = []
	while picked.size() < count and not candidates.is_empty():
		var weights := PackedFloat32Array()
		for upgrade in candidates:
			weights.append(pool.rarity_weights[upgrade.rarity])
		var index := rng.rand_weighted(weights)
		picked.append(candidates[index])
		candidates.remove_at(index)
	return picked


## One drop upgrade for a pickup: roll a rarity (shifted up by `rarity_bonus` tiers), then an upgrade of it.
## Falls back to any available upgrade when that rarity has none left.
static func roll_drop(pool: UpgradePool, owned: Array[UpgradeDef], rarity_bonus: int, rng: RandomNumberGenerator) -> UpgradeDef:
	var candidates := available(pool, owned, UpgradeDef.Source.DROP)
	if candidates.is_empty():
		return null
	var rarity := mini(rng.rand_weighted(PackedFloat32Array(pool.rarity_weights)) + rarity_bonus, UpgradeDef.Rarity.EPIC)
	# No candidate at the rolled tier: step down to the best tier that has one.
	for tier in range(rarity, -1, -1):
		var options := candidates.filter(func(u: UpgradeDef) -> bool: return u.rarity == tier)
		if not options.is_empty():
			return options[rng.randi() % options.size()]
	return candidates[rng.randi() % candidates.size()]
