extends Node
## The roster sheet: data/roster/enemies.csv, elites.csv and bosses.csv hold every enemy's,
## elite's and boss's numbers, look and traits. Loaded at startup, the sheet overrides the
## matching data/enemies/*.tres and data/elites/*.tres (the cached resources the stages use) and
## creates the rows that have no .tres. See data/roster/README.md.

const SHEETS := "res://data/roster/"
const ENEMY_DIR := "res://data/enemies/"
const ELITE_DIR := "res://data/elites/"
const VISUAL_DIR := "res://assets/art/dusk_armada/enemies/"
const BRAIN_DIR := "res://data/brains/"
## Trait names used in the sheet.
const ENEMY_TRAITS := {
	"blink": "res://scenes/enemies/traits/blink_trait.gd",
	"dash": "res://scenes/enemies/traits/dash_trait.gd",
	"mend": "res://scenes/enemies/traits/mend_trait.gd",
	"mine": "res://scenes/enemies/traits/mine_trait.gd",
	"plate": "res://scenes/enemies/traits/plate_trait.gd",
	"rock_drop": "res://scenes/enemies/traits/rock_drop_trait.gd",
	"split": "res://scenes/enemies/traits/split_trait.gd",
	"blade_slash": "res://scenes/enemies/traits/blade_slash_trait.gd",
	"fire_bar": "res://scenes/enemies/traits/fire_bar_trait.gd",
	"slot_jam": "res://scenes/enemies/traits/slot_jam_trait.gd",
	"evolve": "res://scenes/enemies/traits/evolve_trait.gd",
	"flagship": "res://scenes/enemies/traits/flagship_trait.gd",
	"scrap_thief": "res://scenes/enemies/traits/scrap_thief_trait.gd",
	"hard_hat": "res://scenes/enemies/traits/hard_hat_trait.gd",
	"wind_gust": "res://scenes/enemies/traits/wind_gust_trait.gd",
	"boomerang": "res://scenes/enemies/traits/boomerang_trait.gd",
	"spawner_pipe": "res://scenes/enemies/traits/spawner_pipe_trait.gd",
}
const ELITE_TRAITS := {
	"frost_shell": "res://scenes/enemies/elites/frost_shell.gd",
	"gravity": "res://scenes/enemies/elites/gravity_trait.gd",
	"hive_tow": "res://scenes/enemies/elites/hive_tow.gd",
	"meteor_call": "res://scenes/enemies/elites/meteor_call.gd",
	"mirror": "res://scenes/enemies/elites/mirror_trait.gd",
	"phase": "res://scenes/enemies/elites/phase_trait.gd",
	"puppeteer": "res://scenes/enemies/elites/puppeteer.gd",
	"rock_tow": "res://scenes/enemies/elites/rock_tow.gd",
	"shield_link": "res://scenes/enemies/elites/shield_link.gd",
	"sweep": "res://scenes/enemies/elites/sweep_trait.gd",
	"twin": "res://scenes/enemies/elites/twin_trait.gd",
	"gravity_pool": "res://scenes/enemies/elites/gravity_pool_trait.gd",
	"blade_release": "res://scenes/enemies/elites/blade_release_trait.gd",
	"orbit_guard": "res://scenes/enemies/elites/orbit_guard_trait.gd",
	"decoy": "res://scenes/enemies/elites/decoy_trait.gd",
	"reflect_shield": "res://scenes/enemies/elites/reflect_shield_trait.gd",
	"weakness": "res://scenes/enemies/elites/weakness_trait.gd",
	"copy_weapon": "res://scenes/enemies/elites/copy_weapon_trait.gd",
	"scatter_body": "res://scenes/enemies/elites/scatter_body_trait.gd",
	"leaf_shield": "res://scenes/enemies/elites/leaf_shield_trait.gd",
	"multi_part": "res://scenes/enemies/elites/multi_part_trait.gd",
}
## Sheet columns that name a different property.
const COLUMN_PROPS := {"visual": "visual_scene", "scale": "visual_scale", "name": "display_name"}

## Problems found while reading the sheet (also pushed as errors). Tests require none.
var errors: PackedStringArray = []
var _enemies := {}
var _elites := {}
## Elite difficulty levels (elite_levels.csv), lowest first.
var levels: Array[EliteLevel] = []


func _init() -> void:
	load_sheets(SHEETS)


func enemy(id: StringName) -> EnemyDef:
	return _enemies.get(id)


## An elite or boss.
func elite(id: StringName) -> EliteDef:
	return _elites.get(id)


func enemy_ids() -> Array:
	return _enemies.keys()


func elite_ids() -> Array:
	return _elites.keys()


func load_sheets(dir: String) -> void:
	errors.clear()
	var enemy_rows := read_csv(dir + "enemies.csv")
	var elite_rows := read_csv(dir + "elites.csv") + read_csv(dir + "bosses.csv")
	# Make every def first, so trait settings can name any enemy (split fragment=...).
	for row in enemy_rows:
		_enemies[StringName(row["id"])] = _def_for(row["id"], ENEMY_DIR, EnemyDef)
	for row in elite_rows:
		_elites[StringName(row["id"])] = _def_for(row["id"], ELITE_DIR, BossDef if row.has("phases") else EliteDef)
	for row in enemy_rows:
		_apply(enemy(row["id"]), row, ENEMY_TRAITS)
	for row in elite_rows:
		_apply(elite(row["id"]), row, ELITE_TRAITS)
	_load_levels(read_csv(dir + "elite_levels.csv"))
	for e in errors:
		push_error("Roster: " + e)


func _load_levels(rows: Array[Dictionary]) -> void:
	levels.clear()
	for row in rows:
		var made := EliteLevel.new()
		for column: String in row:
			set_property(made, column, row[column], "elite_levels row " + row["level"])
		levels.append(made)
	levels.sort_custom(func(a: EliteLevel, b: EliteLevel) -> bool: return a.level < b.level)
	if levels.is_empty():
		levels.append(EliteLevel.new())


## The level an elite rolls on stage number `stage` (1-based): any level whose first stage has
## come, `roll` in 0..1 picking among them (later stages also tilt toward the higher ones).
func level_for(stage: int, roll: float) -> EliteLevel:
	var open: Array[EliteLevel] = []
	for l in levels:
		if l.from_stage <= stage:
			open.append(l)
	if open.is_empty():
		return levels[0]
	return open[mini(open.size() - 1, int(pow(roll, 0.8) * open.size()))]


## Level `number` exactly (dev option level=N), clamped to the levels that exist.
func level_number(number: int) -> EliteLevel:
	return levels[clampi(number - 1, 0, levels.size() - 1)]


## Rows of a CSV file as Dictionaries keyed by the header. Blank rows and # comments are skipped.
func read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("missing sheet " + path)
		return rows
	var header := file.get_csv_line()
	while not file.eof_reached():
		var cells := file.get_csv_line()
		if cells.size() < 2 or cells[0].strip_edges().is_empty() or cells[0].begins_with("#"):
			continue
		var row := {}
		for i in mini(header.size(), cells.size()):
			row[header[i].strip_edges()] = cells[i].strip_edges()
		rows.append(row)
	return rows


func _def_for(id: String, dir: String, type: Variant) -> Resource:
	var path := dir + id + ".tres"
	if ResourceLoader.exists(path):
		return load(path)  # Cached: the stages get this same, patched resource.
	var def: Resource = type.new()
	def.set("id", StringName(id))
	return def


func _apply(def: Resource, row: Dictionary, registry: Dictionary) -> void:
	var where := "%s row %s" % ["enemies" if def is EnemyDef else "elites", row["id"]]
	for column: String in row:
		var raw: String = row[column]
		match column:
			"id":
				pass
			"traits":
				def.set("trait_logic", null)
				(def.get("traits") as Array).assign(parse_traits(raw, registry, where))
			"phases":
				(def.get("phases") as Array).assign(_parse_phases(raw, where))
			"visual":
				var path := VISUAL_DIR + raw + ".tscn"
				if ResourceLoader.exists(path):
					def.set("visual_scene", load(path))
				else:
					errors.append("%s: no visual %s" % [where, path])
			"brain":
				var path := BRAIN_DIR + raw + ".tres"
				if ResourceLoader.exists(path):
					def.set("brain", load(path))
				else:
					errors.append("%s: no brain %s" % [where, path])
			_:
				if not raw.is_empty():
					set_property(def, COLUMN_PROPS.get(column, column), raw, where)


## "blink(interval=1.2 distance=90); plate" -> trait resources with those settings.
func parse_traits(text: String, registry: Dictionary, where: String) -> Array:
	var made := []
	for token in _split_top(text, ";"):
		var name := token.get_slice("(", 0).strip_edges()
		if name.is_empty():
			continue
		if not registry.has(name):
			errors.append("%s: unknown trait '%s'" % [where, name])
			continue
		if not ResourceLoader.exists(registry[name]):
			errors.append("%s: trait '%s' has no script yet (%s)" % [where, name, registry[name]])
			continue
		var t: Resource = load(registry[name]).new()
		if "(" in token:
			for pair in token.get_slice("(", 1).trim_suffix(")").split(" ", false):
				var kv := pair.split("=", true, 1)
				if kv.size() != 2:
					errors.append("%s: '%s' needs name=value" % [where, pair])
				else:
					set_property(t, kv[0], kv[1], "%s %s" % [where, name])
		made.append(t)
	return made


## "100: shield_link | 60: hive_tow; mirror" -> BossPhases (percent of max hp where each starts).
func _parse_phases(text: String, where: String) -> Array[BossPhase]:
	var phases: Array[BossPhase] = []
	for part in _split_top(text, "|"):
		var phase := BossPhase.new()
		phase.at = part.get_slice(":", 0).strip_edges().trim_suffix("%").to_float() / 100.0
		phase.traits.assign(parse_traits(part.substr(part.find(":") + 1), ELITE_TRAITS, where))
		phases.append(phase)
	phases.sort_custom(func(a: BossPhase, b: BossPhase) -> bool: return a.at > b.at)
	return phases


## Sets `prop` on `obj` from sheet text, converted to the property's type.
func set_property(obj: Object, prop: String, raw: String, where: String) -> void:
	for info in obj.get_property_list():
		if info["name"] != prop:
			continue
		var value: Variant = _convert(raw, info)
		if value == null:
			errors.append("%s: bad value '%s' for %s" % [where, raw, prop])
		else:
			obj.set(prop, value)
		return
	errors.append("%s: no setting called '%s'" % [where, prop])


func _convert(raw: String, info: Dictionary) -> Variant:
	match info["type"]:
		TYPE_INT:
			return raw.to_int() if raw.is_valid_int() else null
		TYPE_FLOAT:
			return raw.to_float() if raw.is_valid_float() else null
		TYPE_BOOL:
			return raw.to_lower() in ["1", "true", "yes"]
		TYPE_STRING:
			return raw
		TYPE_STRING_NAME:
			return StringName(raw)
		TYPE_COLOR:
			var parts := raw.split(" ", false)
			if parts.size() >= 3:
				return Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float() if parts.size() > 3 else 1.0)
			return Color.from_string(raw, Color.WHITE)
		TYPE_OBJECT:
			match String(info["hint_string"]):
				"EnemyDef":
					return enemy(raw)
				"EnemyBrain":
					return load(BRAIN_DIR + raw + ".tres") if ResourceLoader.exists(BRAIN_DIR + raw + ".tres") else null
				_:
					return load(raw) if ResourceLoader.exists(raw) else null
	return null


## Splits on `sep` outside parentheses.
func _split_top(text: String, sep: String) -> PackedStringArray:
	var parts := PackedStringArray()
	var depth := 0
	var current := ""
	for c in text:
		if c == "(":
			depth += 1
		elif c == ")":
			depth -= 1
		if c == sep and depth == 0:
			parts.append(current.strip_edges())
			current = ""
		else:
			current += c
	if not current.strip_edges().is_empty():
		parts.append(current.strip_edges())
	return parts
