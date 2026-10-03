class_name StatWords
extends RefCounted
## Run stats in the units a player reads: shots per second, seconds, percent, counts. Used by the
## hangar to show what an upgrade changes ("Damage 2 → 3").

const BASE_WEAPON: WeaponDef = preload("res://data/weapons/basic.tres")
const SHIELD_SECONDS := 12.0
const BASE_LIVES := 1

## stat: [name, kind]. Kinds: pct (a multiplier as %), count (base + value), plain, rate (shots/s),
## recharge (seconds per layer), seconds, px.
const FORMATS := {
	&"fire_rate": ["Fire rate", "rate"], &"extra_shots": ["Shots", "count"], &"damage": ["Damage", "count"],
	&"pierce": ["Pierce", "plain"], &"homing": ["Homing", "plain"], &"projectile_speed": ["Shot speed", "pct"],
	&"missiles": ["Missiles", "plain"], &"missile_rate": ["Missile rate", "pct"], &"drones": ["Drones", "plain"],
	&"move_speed": ["Speed", "pct"], &"strafe_left": ["Strafe left", "pct"], &"strafe_right": ["Strafe right", "pct"],
	&"shield_recharge": ["Recharge", "recharge"], &"shield_layers": ["Layers", "count"], &"magnet": ["Pull range", "px"],
	&"overdrive_window": ["Overkill gain", "pct"], &"graze_gain": ["Graze gain", "pct"], &"chain_gain": ["Chain gain", "pct"],
	&"explode_radius": ["Burst radius", "px"], &"freeze_charges": ["Novas", "plain"], &"freeze_time": ["Slow", "seconds"],
	&"scrap_mult": ["Scrap value", "pct"], &"extra_lives": ["Ships", "lives"], &"spread": ["Spread", "plain"],
	&"shield_reflect": ["Reflect", "plain"], &"shield_combo": ["Shield combo", "plain"], &"blink": ["Blink", "plain"],
	&"ricochet": ["Ricochet", "plain"], &"wingman": ["Wingman", "plain"],
	&"bounces": ["Bounces", "plain"], &"shrapnel": ["Shrapnel", "plain"], &"blast_radius": ["Blast radius", "px"],
	&"max_active": ["Mines out", "plain"], &"shot_size": ["Bubble size", "pct"], &"ball_size": ["Ball size", "pct"],
	&"hypno_time": ["Hypno time", "seconds"], &"pull_time": ["Pull time", "seconds"], &"pull_radius": ["Pull radius", "px"],
}


## `weapon` (the part's own gun, if any) supplies the base for rate, shots, damage and pierce.
static func value(stat: StringName, v: float, weapon: WeaponDef = null) -> String:
	var kind: String = FORMATS.get(stat, ["", "plain"])[1]
	if weapon:
		match stat:
			&"damage":
				return str(roundi(weapon.damage + v))
			&"pierce":
				return str(roundi(weapon.pierce + v))
			&"extra_shots":
				return str(roundi(weapon.spread_count + v))
			&"fire_rate":
				return "%.1f/s" % (weapon.fire_rate * v)
			&"bounces":
				return str(roundi(weapon.bounces + v))
			&"shrapnel":
				return str(roundi(weapon.shrapnel + v))
			&"blast_radius":
				return "%d" % roundi(weapon.blast_radius + v)
			&"max_active":
				return str(weapon.cap(roundi(v)))
			&"hypno_time":
				return "%.1fs" % (HypnoControl.BASE_TIME + v)
			&"pull_time":
				return "%.1fs" % (GravityWell.BASE_PULL_TIME + v)
			&"pull_radius":
				return "%d" % roundi(GravityWell.BASE_PULL_RADIUS + v)
	match kind:
		"pct":
			return "%d%%" % roundi(v * 100.0)
		"count":
			return str(roundi(v) + 1)
		"rate":
			return "%.1f/s" % (BASE_WEAPON.fire_rate * v)
		"recharge":
			return "%.1fs" % (SHIELD_SECONDS * v)
		"seconds":
			return "%.1fs" % v
		"px":
			return "%d" % roundi(v)
		"lives":
			return str(roundi(v) + BASE_LIVES)
	return str(snappedf(v, 0.1)) if v != roundf(v) else str(roundi(v))


static func name(stat: StringName) -> String:
	return FORMATS.get(stat, [String(stat), ""])[0]


## "Damage 2 → 3, Shots 1 → 2" for each stat in `effects`, from stats `before` to `after`.
static func change(effects: Array, before: Dictionary, after: Dictionary, weapon: WeaponDef = null) -> String:
	var parts: PackedStringArray = []
	var seen: Array[StringName] = []
	for e: Dictionary in effects:
		var stat: StringName = e["stat"]
		if stat in seen:
			continue
		seen.append(stat)
		var a := value(stat, before[stat], weapon)
		var b := value(stat, after[stat], weapon)
		parts.append("%s %s" % [name(stat), a if a == b else "%s → %s" % [a, b]])
	return ", ".join(parts)
