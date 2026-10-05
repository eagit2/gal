class_name MentorRules
extends RefCounted
## Mentor cutscene rules (CutsceneDef) on the save slot's mentor record and hangar state. Pure
## functions so tests can call them directly. Record: {"deaths": deaths in a row on the stage,
## "given": part lent, "done": part taken back (never plays again), "replaced": part id the lent
## part swapped out, "attempts": stage starts since the lend, "clean": no hit this attempt}.


static func fresh() -> Dictionary:
	return {"deaths": 0, "given": false, "done": false, "replaced": "", "attempts": 0, "clean": true}


## The record for `def` in the save data (created on first use).
static func record(data: Dictionary, def: CutsceneDef) -> Dictionary:
	if not data.get("mentor") is Dictionary:
		data["mentor"] = {}
	var all: Dictionary = data["mentor"]
	if not all.get(String(def.id)) is Dictionary:
		all[String(def.id)] = fresh()
	var m: Dictionary = all[String(def.id)]
	for key in fresh():
		if not m.has(key):
			m[key] = fresh()[key]
	return m


static func stage_started(m: Dictionary, stage_id: StringName, def: CutsceneDef) -> void:
	if stage_id == def.stage_id and m["given"] and not m["done"]:
		m["attempts"] = int(m["attempts"]) + 1
		m["clean"] = true


static func struck(m: Dictionary, stage_id: StringName, def: CutsceneDef) -> void:
	if stage_id == def.stage_id:
		m["clean"] = false


static func died(m: Dictionary, stage_id: StringName, def: CutsceneDef) -> void:
	if stage_id == def.stage_id and not m["given"] and not m["done"]:
		m["deaths"] = int(m["deaths"]) + 1


## A clear without the lend just resets the death streak.
static func cleared(m: Dictionary, stage_id: StringName, def: CutsceneDef) -> void:
	if stage_id == def.stage_id and not m["given"]:
		m["deaths"] = 0


static func wants_intro(m: Dictionary, stage_id: StringName, def: CutsceneDef) -> bool:
	return stage_id == def.stage_id and not m["given"] and not m["done"] and int(m["deaths"]) >= def.deaths_to_trigger


static func wants_take_back(m: Dictionary, stage_id: StringName, def: CutsceneDef) -> bool:
	return stage_id == def.stage_id and m["given"] and not m["done"]


## Lends the part at max level on its mount, remembering what it replaced.
static func grant(catalog: HangarCatalog, state: Dictionary, m: Dictionary, def: CutsceneDef) -> void:
	var part := catalog.part(def.grant_part)
	var levels := {}
	for a in part.attributes:
		levels[String(a["id"])] = int(a["max"])
	state["parts"][String(part.id)] = levels
	var mount := String(def.grant_mount)
	m["replaced"] = String(state["mounts"].get(mount, ""))
	var old := Loadout.mount_of(state, part.id)
	if old != &"":
		state["mounts"][String(old)] = ""
	state["mounts"][mount] = String(part.id)
	m["given"] = true
	m["attempts"] = 0
	m["clean"] = true


## Takes the lent part back (only that part; its chips are built in), re-fits what it replaced and
## leaves one reward chip.
static func take_back(state: Dictionary, m: Dictionary, def: CutsceneDef) -> void:
	var id := String(def.grant_part)
	for mount: String in state["mounts"]:
		if state["mounts"][mount] == id:
			state["mounts"][mount] = ""
	state["parts"].erase(id)
	state["sockets"].erase(id)
	var replaced := String(m["replaced"])
	var mount := String(def.grant_mount)
	if replaced != "" and state["parts"].has(replaced) and String(state["mounts"].get(mount, "")) == "":
		var elsewhere := Loadout.mount_of(state, StringName(replaced))
		if elsewhere != &"":
			state["mounts"][String(elsewhere)] = ""
		state["mounts"][mount] = replaced
	var chip := String(def.reward_chip)
	state["chips"][chip] = int(state["chips"].get(chip, 0)) + 1
	m["done"] = true


static func take_back_line(m: Dictionary, def: CutsceneDef) -> String:
	if m["clean"] and int(m["attempts"]) == 1:
		return def.line_first_clean
	if m["clean"] and int(m["attempts"]) > 1:
		return def.line_retry_clean
	return def.line_fallback
