class_name Loadout
extends RefCounted
## Hangar rules on the saved loadout state. Pure functions so tests can call them directly.
## State: {"frame": id, "frames": [ids], "modules": [{"id", "ap", "born"}], "equipped": [module index or -1 per slot]}

const SLOTS := 6


static func default_state(catalog: ModuleCatalog) -> Dictionary:
	var modules: Array = []
	for id in catalog.starter_modules:
		modules.append({"id": String(id), "ap": 0, "born": false})
	var equipped: Array = []
	equipped.resize(SLOTS)
	equipped.fill(-1)
	var first := String(catalog.frames[0].id)
	return {"frame": first, "frames": [first], "modules": modules, "equipped": equipped}


## Returns a usable state, replacing anything from an older or broken save.
static func normalize(state: Variant, catalog: ModuleCatalog) -> Dictionary:
	if not (state is Dictionary and state.has("frame") and state.has("modules") and state.has("equipped")):
		return default_state(catalog)
	var equipped: Array = state["equipped"]
	for slot in equipped.size():
		equipped[slot] = int(equipped[slot])
		if equipped[slot] >= (state["modules"] as Array).size():
			equipped[slot] = -1
	return state


static func frame_of(catalog: ModuleCatalog, state: Dictionary) -> FrameDef:
	var frame := catalog.frame(StringName(state["frame"]))
	return frame if frame else catalog.frames[0]


static func def_at(catalog: ModuleCatalog, state: Dictionary, index: int) -> ModuleDef:
	if index < 0:
		return null
	return catalog.module(StringName(state["modules"][index]["id"]))


static func level_of(catalog: ModuleCatalog, state: Dictionary, index: int) -> int:
	var def := def_at(catalog, state, index)
	return def.level_for(int(state["modules"][index]["ap"])) if def else 0


## Module index in `slot`, or -1 when the slot is empty or outside the frame.
static func in_slot(catalog: ModuleCatalog, state: Dictionary, slot: int) -> int:
	return int(state["equipped"][slot]) if slot < frame_of(catalog, state).slots else -1


## True when a support module in `slot` has a partner it can boost.
static func link_active(catalog: ModuleCatalog, state: Dictionary, slot: int) -> bool:
	var def := def_at(catalog, state, in_slot(catalog, state, slot))
	var partner := frame_of(catalog, state).partner(slot)
	if def == null or def.kind != ModuleDef.Kind.SUPPORT or partner < 0:
		return false
	var other := def_at(catalog, state, in_slot(catalog, state, partner))
	return other != null and other.kind != ModuleDef.Kind.SUPPORT and (def.link_kind < 0 or other.kind == def.link_kind)


## Level the module in `slot` works at, including amplify from a linked support module.
static func slot_level(catalog: ModuleCatalog, state: Dictionary, slot: int) -> int:
	var level := level_of(catalog, state, in_slot(catalog, state, slot))
	var partner := frame_of(catalog, state).partner(slot)
	if partner >= 0 and link_active(catalog, state, partner):
		level += def_at(catalog, state, in_slot(catalog, state, partner)).amplify
	return level


## Every effect the frame and equipped modules give, for GameState.set_meta_effects.
static func effects(catalog: ModuleCatalog, state: Dictionary) -> Array[Dictionary]:
	var frame := frame_of(catalog, state)
	var result: Array[Dictionary] = frame.effects.duplicate()
	for slot in frame.slots:
		var def := def_at(catalog, state, in_slot(catalog, state, slot))
		if def == null or (def.kind == ModuleDef.Kind.SUPPORT and not link_active(catalog, state, slot)):
			continue
		result.append_array(def.effects)
		for i in slot_level(catalog, state, slot) - 1:
			result.append_array(def.per_level)
	return result


## Puts module `index` in `slot` (moving it if it was equipped elsewhere); -1 empties the slot.
static func equip(state: Dictionary, slot: int, index: int) -> void:
	var equipped: Array = state["equipped"]
	if index >= 0:
		for s in equipped.size():
			if equipped[s] == index:
				equipped[s] = -1
	equipped[slot] = index


## Adds AP to every equipped module. Newly mastered modules spawn a level-1 copy (once each).
## Returns the defs mastered by this call.
static func add_ap(catalog: ModuleCatalog, state: Dictionary, amount: int) -> Array[ModuleDef]:
	var mastered: Array[ModuleDef] = []
	for slot in frame_of(catalog, state).slots:
		var index := in_slot(catalog, state, slot)
		if index < 0:
			continue
		var module: Dictionary = state["modules"][index]
		var def := def_at(catalog, state, index)
		var before := def.level_for(int(module["ap"]))
		module["ap"] = int(module["ap"]) + amount
		if before < def.max_level() and def.level_for(module["ap"]) == def.max_level():
			mastered.append(def)
			if not module.get("born", false):
				module["born"] = true
				(state["modules"] as Array).append({"id": module["id"], "ap": 0, "born": true})
	return mastered


static func owns(state: Dictionary, id: StringName) -> bool:
	return (state["modules"] as Array).any(func(m: Dictionary) -> bool: return StringName(m["id"]) == id)


static func is_mastered(catalog: ModuleCatalog, state: Dictionary, id: StringName) -> bool:
	var def := catalog.module(id)
	return def != null and (state["modules"] as Array).any(func(m: Dictionary) -> bool: return StringName(m["id"]) == id and def.level_for(int(m["ap"])) == def.max_level())


## Shown in the shop: not owned yet, and its chain requirement (if any) is mastered.
static func in_shop(catalog: ModuleCatalog, state: Dictionary, def: ModuleDef) -> bool:
	return not owns(state, def.id) and (def.requires_mastered == &"" or is_mastered(catalog, state, def.requires_mastered))


static func set_frame(catalog: ModuleCatalog, state: Dictionary, id: StringName) -> void:
	state["frame"] = String(id)
	var slots := frame_of(catalog, state).slots
	for slot in range(slots, SLOTS):
		state["equipped"][slot] = -1
