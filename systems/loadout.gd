class_name Loadout
extends RefCounted
## Hangar rules on the saved loadout state. Pure functions so tests can call them directly.
## State: {"ship": id, "ships": [ids], "parts": {id: {attribute id: level}}, "mounts": {mount: part
## id or ""}, "pilot": id, "pilots": [ids], "stock": [part ids for sale], "tree": {ship id: {node
## id: rank}}, "cleared": [stage ids ever cleared, for ship unlocks], "chips": {chip id: copies
## owned}, "sockets": {part id: [chip id or "" per socket]}}. Store stock lives in HangarStock, tree rules in ShipTree.


static func default_state(catalog: HangarCatalog) -> Dictionary:
	var ship := String(catalog.ships[0].id)
	var pilot := String(catalog.pilots[0].id)
	var parts := {}
	var mounts := {}
	for mount in catalog.ships[0].mounts:
		mounts[String(mount)] = ""
	for mount in catalog.starter_mounts:
		var id := String(catalog.starter_mounts[mount])
		parts[id] = {}
		mounts[String(mount)] = id
	return {"ship": ship, "ships": [ship], "parts": parts, "mounts": mounts, "pilot": pilot, "pilots": [pilot], "stock": [], "tree": {}, "cleared": [], "chips": {}, "sockets": {}}


## Returns a usable state. Saves from before ship slots keep their pilots and start a fresh loadout;
## saves from ranked parts keep their parts at attribute level 0.
static func normalize(state: Variant, catalog: HangarCatalog) -> Dictionary:
	var fresh := default_state(catalog)
	if not state is Dictionary:
		return fresh
	if state.has("pilot") and catalog.pilot(StringName(state["pilot"])):
		fresh["pilot"] = state["pilot"]
		fresh["pilots"] = state.get("pilots", [state["pilot"]])
	if not (state.has("parts") and state.has("mounts") and state["parts"] is Dictionary):
		return fresh
	for id: String in state["parts"].keys():
		var def := catalog.part(StringName(id))
		if def == null:
			state["parts"].erase(id)
			continue
		var levels: Dictionary = state["parts"][id] if state["parts"][id] is Dictionary else {}
		for attr: String in levels.keys():
			var a := def.attribute(StringName(attr))
			if a.is_empty():
				levels.erase(attr)
			else:
				levels[attr] = clampi(int(levels[attr]), 0, int(a["max"]))
		state["parts"][id] = levels
	for mount: String in fresh["mounts"]:
		var id := String(state["mounts"].get(mount, ""))
		state["mounts"][mount] = id if state["parts"].has(id) else ""
	state["pilot"] = fresh["pilot"]
	state["pilots"] = fresh["pilots"]
	var stock: Array = state.get("stock", []) if state.get("stock") is Array else []
	state["stock"] = stock.filter(func(id: Variant) -> bool: return catalog.part(StringName(str(id))) != null)
	if not state.get("tree") is Dictionary:
		state["tree"] = {}
	if not state.get("cleared") is Array:
		state["cleared"] = []
	for key in ["chips", "sockets"]:
		if not state.get(key) is Dictionary:
			state[key] = {}
	var ship := catalog.ship(StringName(str(state.get("ship", ""))))
	if ship == null or not unlocked(state, ship):
		state["ship"] = fresh["ship"]
	return state


## True when the ship needs no stage, or its stage has been cleared.
static func unlocked(state: Dictionary, ship: ShipDef) -> bool:
	return ship.unlock_stage == &"" or String(ship.unlock_stage) in (state.get("cleared", []) as Array)


static func pilot_of(catalog: HangarCatalog, state: Dictionary) -> PilotDef:
	var pilot := catalog.pilot(StringName(state["pilot"]))
	return pilot if pilot else catalog.pilots[0]


static func ship_of(catalog: HangarCatalog, state: Dictionary) -> ShipDef:
	var ship := catalog.ship(StringName(state["ship"]))
	return ship if ship else catalog.ships[0]


static func owns(state: Dictionary, id: StringName) -> bool:
	return state["parts"].has(String(id))


## Level of a part's attribute; 0 when not upgraded or not owned.
static func level(state: Dictionary, id: StringName, attr: StringName) -> int:
	return int((state["parts"].get(String(id), {}) as Dictionary).get(String(attr), 0))


## Attribute levels added up, for how the part looks on the ship.
static func total_levels(state: Dictionary, id: StringName) -> int:
	var total := 0
	for value: Variant in (state["parts"].get(String(id), {}) as Dictionary).values():
		total += int(value)
	return total


## How the part looks: 1 plain, 2 glowing (4+ levels), 3 doubled (9+ levels).
static func look(state: Dictionary, id: StringName) -> int:
	var total := total_levels(state, id)
	return 3 if total >= 9 else (2 if total >= 4 else 1)


static func part_at(catalog: HangarCatalog, state: Dictionary, mount: StringName) -> PartDef:
	var id := String(state["mounts"].get(String(mount), ""))
	return catalog.part(StringName(id)) if id != "" else null


## Mount the part sits on, or &"" when it isn't fitted.
static func mount_of(state: Dictionary, id: StringName) -> StringName:
	for mount: String in state["mounts"]:
		if state["mounts"][mount] == String(id):
			return StringName(mount)
	return &""


## True when the owned part fits `mount`: the mount takes its kind, and the ship has a free slot
## of that type (moving the part, or swapping out what sits there, frees one).
static func can_place(catalog: HangarCatalog, state: Dictionary, mount: StringName, def: PartDef) -> bool:
	var ship := ship_of(catalog, state)
	if not owns(state, def.id) or not ship.accepts(mount, def):
		return false
	var used := 0
	for other in ship.mounts:
		var part := part_at(catalog, state, other)
		if other != mount and part and part != def and part.slot() == def.slot():
			used += 1
	return used < int(ship.slots.get(def.slot(), 0))


## Fits part `id` on `mount` (moving it off any other mount); "" empties the mount. Returns false
## when it doesn't fit.
static func place(catalog: HangarCatalog, state: Dictionary, mount: StringName, id: StringName) -> bool:
	if id != &"":
		var def := catalog.part(id)
		if def == null or not can_place(catalog, state, mount, def):
			return false
		var old := mount_of(state, id)
		if old != &"":
			state["mounts"][String(old)] = ""
	state["mounts"][String(mount)] = String(id)
	return true


## Every effect the fitted parts give (base, attribute levels, where they sit) plus the ship tree, for GameState.
static func effects(catalog: HangarCatalog, state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for mount in ship_of(catalog, state).mounts:
		var def := part_at(catalog, state, mount)
		if def:
			result.append_array(def.effects_at(state["parts"][String(def.id)]))
			result.append_array(catalog.placement_effects(def, mount))
	result.append_array(ShipTree.effects(catalog, state))
	for mount in ship_of(catalog, state).mounts:
		var def := part_at(catalog, state, mount)
		if def == null:
			continue
		for id in chips_in(catalog, state, def):
			if id != "":
				result.append_array(catalog.chip(StringName(id)).effects)
	for combo in active_combos(catalog, state):
		result.append_array(combo.effects)
	return result


## Chip ids in a part's sockets, one per socket ("" = empty), in Loadout.sockets order.
static func chips_in(catalog: HangarCatalog, state: Dictionary, def: PartDef) -> Array[String]:
	var count := 0
	for group in sockets(catalog, state, def):
		count += maxi(group, 1)
	var saved: Array = state["sockets"].get(String(def.id), [])
	if not def.locked_chips.is_empty():
		saved = def.locked_chips.map(func(c: StringName) -> String: return String(c))
	var result: Array[String] = []
	for i in count:
		var id := str(saved[i]) if i < saved.size() else ""
		result.append(id if catalog.chip(StringName(id)) else "")
	return result


## Socket index pairs that are linked, from a part's socket groups.
static func linked_pairs(groups: Array[int]) -> Array[Vector2i]:
	var pairs: Array[Vector2i] = []
	var i := 0
	for group in groups:
		if group == 2:
			pairs.append(Vector2i(i, i + 1))
		i += maxi(group, 1)
	return pairs


## Copies of a chip not sitting in any socket.
static func chips_free(state: Dictionary, chip: StringName) -> int:
	var used := 0
	for list: Array in state["sockets"].values():
		used += list.count(String(chip))
	return int(state["chips"].get(String(chip), 0)) - used


## Puts an owned chip (or "" to empty it) in socket `index` of an owned part. False when no free copy.
static func set_chip(catalog: HangarCatalog, state: Dictionary, def: PartDef, index: int, chip: StringName) -> bool:
	var list := chips_in(catalog, state, def)
	if index < 0 or index >= list.size() or not owns(state, def.id) or not def.locked_chips.is_empty():
		return false
	if chip != &"" and list[index] != String(chip) and chips_free(state, chip) <= 0:
		return false
	list[index] = String(chip)
	state["sockets"][String(def.id)] = list
	return true


## Combos from linked chip pairs on fitted parts.
static func active_combos(catalog: HangarCatalog, state: Dictionary) -> Array[LinkComboDef]:
	var result: Array[LinkComboDef] = []
	for mount in ship_of(catalog, state).mounts:
		var def := part_at(catalog, state, mount)
		if def:
			result.append_array(part_combos(catalog, state, def))
	return result


## Combos formed in one part's linked sockets.
static func part_combos(catalog: HangarCatalog, state: Dictionary, def: PartDef) -> Array[LinkComboDef]:
	var result: Array[LinkComboDef] = []
	var list := chips_in(catalog, state, def)
	for pair in linked_pairs(sockets(catalog, state, def)):
		var combo := catalog.combo_for(StringName(list[pair.x]), StringName(list[pair.y]))
		if combo:
			result.append(combo)
	return result


## Link sockets on a part, linked pairs first: 2 = a linked pair, 1 = a single socket, 0 = a
## single socket the ship tree adds.
static func sockets(catalog: HangarCatalog, state: Dictionary, def: PartDef) -> Array[int]:
	var groups := PartDef.socket_groups(def.sockets, def.links)
	for i in ShipTree.extra_sockets(catalog, state, def.category):
		groups.append(0)
	return groups


## Scrap for the next level of an attribute; -1 when it is maxed or the part isn't owned.
static func upgrade_price(state: Dictionary, def: PartDef, attr: StringName) -> int:
	var a := def.attribute(attr)
	var current := level(state, def.id, attr)
	if a.is_empty() or not owns(state, def.id) or current >= int(a["max"]):
		return -1
	return def.level_price(current + 1)


## Raises an attribute one level. The caller pays.
static func upgrade(state: Dictionary, def: PartDef, attr: StringName) -> void:
	if upgrade_price(state, def, attr) >= 0:
		state["parts"][String(def.id)][String(attr)] = level(state, def.id, attr) + 1


## A copy of the state with `def` owned and fitted on the best mount for it, for store previews.
static func preview(catalog: HangarCatalog, state: Dictionary, def: PartDef) -> Dictionary:
	var copy := state.duplicate(true)
	if not owns(copy, def.id):
		copy["parts"][String(def.id)] = {}
	if mount_of(copy, def.id) != &"":
		return copy
	var ship := ship_of(catalog, copy)
	var target: StringName = &""
	for mount in ship.mounts:
		var part := part_at(catalog, copy, mount)
		if not ship.accepts(mount, def):
			continue
		if part and part.slot() == def.slot():
			target = mount  # swap out the part in the same slot type
			break
		if part == null and target == &"":
			target = mount
	if target != &"":
		copy["mounts"][String(target)] = ""
		place(catalog, copy, target, def.id)
	return copy
