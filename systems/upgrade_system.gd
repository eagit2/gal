class_name UpgradeSystem
extends RefCounted
## Turns effect lists (hangar loadout, pilot power, active combo) into run stats. Pure functions so
## tests can call them directly. Effects: {"stat", "op" (add|mul|max), "value"}.

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
	&"strafe_left": 1.0,  # speed multiplier while moving left (an engine on the right mount)
	&"strafe_right": 1.0,  # speed multiplier while moving right (an engine on the left mount)
	&"shield_recharge": 1.0,  # multiplier on recharge time (lower is faster)
	&"shield_layers": 0,
	&"magnet": 0.0,  # scrap pull radius
	&"score_mult": 1.0,
	&"drop_mult": 1.0,  # scrap pile chance
	&"overdrive_window": 1.0,
	&"graze_gain": 1.0,
	&"chain_gain": 1.0,
	&"explode_radius": 0.0,  # kills damage enemies within this radius
	&"time_scale": 1.0,
	&"graze_score": 0,
	&"freeze_charges": 0,  # Cryo Pulse uses per stage
	&"freeze_time": 3.0,  # seconds Frost Nova slows enemies
	&"scrap_mult": 1.0,  # scrap value
	&"extra_lives": 0,  # ships added to the difficulty's lives (Spare Hull)
	&"shield": 0,  # shield parts fitted; no shield bubble without one
	&"burn": 0,  # hits set enemies burning (Ember chip)
	&"chill": 0,  # hits slow enemies (Frost chip)
	&"chain": 0,  # hits arc to this many nearby enemies (Volt chip)
	# Special weapon shots (WeaponDef bounces, shrapnel, blast_radius, active_cap).
	&"bounces": 0,  # extra enemies a rubber duck bounces on to
	&"shrapnel": 0,  # extra pieces a scrap ball breaks into
	&"blast_radius": 0.0,  # pixels added to a mine's blast
	&"max_active": 0,  # extra mines out at once
	&"shot_size": 1.0,  # bubble size multiplier
	# Ship tree perks the run doesn't use yet (hangar plan phase 6).
	&"shield_reflect": 0,  # shield bounces bullets back
	&"shield_combo": 0,  # shield hits fill the combo meter
	&"blink": 0,  # dash teleports
	&"ricochet": 0,  # reflected shots fire as rails
	&"wingman": 0,  # start each stage with a wingman
}
static func compute(effects: Array[Dictionary]) -> Dictionary:
	var stats := BASE_STATS.duplicate()
	for effect in effects:
		var stat: StringName = effect["stat"]
		if not stats.has(stat):
			continue
		match StringName(effect["op"]):
			&"add":
				stats[stat] += effect["value"]
			&"mul":
				stats[stat] *= effect["value"]
			&"max":
				stats[stat] = maxf(stats[stat], effect["value"])
	return stats
