class_name Powerups
extends RefCounted
## Per-life power-ups: POWER and FIRE RATE multiply by DropTable.powerup_step per pickup (capped),
## +1 SHOT adds one more copy of every gun's volley. Pure functions on a counts dictionary
## {"power": n, "rate": n, "shots": n} so tests can call them directly.

const TABLE: DropTable = preload("res://data/drops/drop_table.tres")
const KINDS: Array[StringName] = [&"power", &"rate", &"shots"]
const LABELS := {&"power": "P", &"rate": "F", &"shots": "+1"}
const NAMES := {&"power": "POWER UP", &"rate": "FIRE RATE UP", &"shots": "+1 SHOT"}
const COLORS := {&"power": Color(1, 0.45, 0.35), &"rate": Color(1, 0.85, 0.3), &"shots": Color(0.45, 0.85, 1)}


static func empty() -> Dictionary:
	return {&"power": 0, &"rate": 0, &"shots": 0}


static func power_mult(counts: Dictionary, table: DropTable) -> float:
	return minf(pow(table.powerup_step, int(counts.get(&"power", 0))), table.max_power)


static func rate_mult(counts: Dictionary, table: DropTable) -> float:
	return minf(pow(table.powerup_step, int(counts.get(&"rate", 0))), table.max_fire_rate)


static func volleys(counts: Dictionary, table: DropTable) -> int:
	return mini(int(counts.get(&"shots", 0)), table.max_extra_volleys)


## True while one more pickup of `kind` still raises it.
static func can_add(counts: Dictionary, kind: StringName, table: DropTable) -> bool:
	match kind:
		&"power":
			return power_mult(counts, table) < table.max_power
		&"rate":
			return rate_mult(counts, table) < table.max_fire_rate
		&"shots":
			return volleys(counts, table) < table.max_extra_volleys
	return false


## Counts one pickup. Returns false (nothing changes) when it is already capped.
static func add(counts: Dictionary, kind: StringName, table: DropTable) -> bool:
	if not can_add(counts, kind, table):
		return false
	counts[kind] = int(counts.get(kind, 0)) + 1
	return true


## Effects for UpgradeSystem, applied after the hangar's so the multipliers scale everything.
static func effects(counts: Dictionary, table: DropTable) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if int(counts.get(&"power", 0)) > 0:
		result.append({"stat": &"power_mult", "op": &"mul", "value": power_mult(counts, table)})
	if int(counts.get(&"rate", 0)) > 0:
		result.append({"stat": &"fire_rate", "op": &"mul", "value": rate_mult(counts, table)})
	if volleys(counts, table) > 0:
		result.append({"stat": &"volleys", "op": &"add", "value": volleys(counts, table)})
	return result


## Whole damage from `base` x `mult`: the fraction becomes a chance of one more point (`roll` in 0..1),
## so x1.1 on 1 damage averages 1.1.
static func scaled_damage(base: int, mult: float, roll: float) -> int:
	var exact := base * mult
	var whole := floori(exact)
	return whole + (1 if roll < exact - whole else 0)


## HUD text: "P2 F1 +1" for the stacks held, "" with none.
static func hud_text(counts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for kind in KINDS:
		var n := int(counts.get(kind, 0))
		if n > 0:
			parts.append("+%d" % n if kind == &"shots" else "%s%d" % [LABELS[kind], n])
	return " ".join(parts)
