class_name Loadout
extends RefCounted
## Hangar rules on the saved loadout state. Pure functions so tests can call them directly.
## State: {"ship": id, "ships": [ids], "parts": {id: rank}, "mounts": {mount: part id or ""},
## "pilot": id, "pilots": [ids]}


static func default_state(catalog: HangarCatalog) -> Dictionary:
	var ship := String(catalog.ships[0].id)
	var pilot := String(catalog.pilots[0].id)
	var parts := {}
	var mounts := {}
	for mount in catalog.ships[0].mounts:
		mounts[String(mount)] = ""
	for mount in catalog.starter_mounts:
		var id := String(catalog.starter_mounts[mount])
		parts[id] = 1
		mounts[String(mount)] = id
	return {"ship": ship, "ships": [ship], "parts": parts, "mounts": mounts, "pilot": pilot, "pilots": [pilot]}


## Returns a usable state. Saves from before ship slots keep their pilots and start a fresh loadout.
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
		state["parts"][id] = clampi(int(state["parts"][id]), 0, PartDef.MAX_RANK)
		if catalog.part(StringName(id)) == null:
			state["parts"].erase(id)
	for mount: String in fresh["mounts"]:
		var id := String(state["mounts"].get(mount, ""))
		state["mounts"][mount] = id if state["parts"].has(id) else ""
	state["pilot"] = fresh["pilot"]
	state["pilots"] = fresh["pilots"]
	return state


static func pilot_of(catalog: HangarCatalog, state: Dictionary) -> PilotDef:
	var pilot := catalog.pilot(StringName(state["pilot"]))
	return pilot if pilot else catalog.pilots[0]


static func ship_of(catalog: HangarCatalog, state: Dictionary) -> ShipDef:
	var ship := catalog.ship(StringName(state["ship"]))
	return ship if ship else catalog.ships[0]


## Owned rank of a part; 0 when not owned.
static func rank_of(state: Dictionary, id: StringName) -> int:
	return int(state["parts"].get(String(id), 0))


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
	if rank_of(state, def.id) == 0 or not ship.accepts(mount, def):
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


## Every effect the fitted parts give, with their rank and where they sit, for GameState.
static func effects(catalog: HangarCatalog, state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for mount in ship_of(catalog, state).mounts:
		var def := part_at(catalog, state, mount)
		if def:
			result.append_array(def.effects_at(rank_of(state, def.id)))
			result.append_array(catalog.placement_effects(def, mount))
	return result


## Scrap for the next rank of a part (buying it is rank 1); -1 when it is maxed.
static func next_price(state: Dictionary, def: PartDef) -> int:
	var rank := rank_of(state, def.id)
	return def.price(rank + 1) if rank < PartDef.MAX_RANK else -1


## Raises a part one rank (buying it at rank 1). The caller pays.
static func rank_up(state: Dictionary, def: PartDef) -> void:
	state["parts"][String(def.id)] = mini(rank_of(state, def.id) + 1, PartDef.MAX_RANK)


## A copy of the state with `def` at `rank` fitted on the best mount for it, for store previews.
static func preview(catalog: HangarCatalog, state: Dictionary, def: PartDef, rank: int) -> Dictionary:
	var copy := state.duplicate(true)
	copy["parts"][String(def.id)] = rank
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
