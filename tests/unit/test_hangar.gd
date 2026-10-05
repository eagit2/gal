extends TestCase
## Hangar loadout rules (typed slots, mounts, placement, attribute levels, store stock, blueprint
## tree) and medal goals.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _stats(state: Dictionary) -> Dictionary:
	return UpgradeSystem.compute(Loadout.effects(CATALOG, state))


func _owning(ids: Array) -> Dictionary:
	var state := Loadout.default_state(CATALOG)
	for id: String in ids:
		state["parts"][id] = {}
	return state


func _medal(goal: MedalDef.Goal, target := 0.0) -> MedalDef:
	var medal := MedalDef.new()
	medal.goal = goal
	medal.target = target
	return medal


func test_every_file_is_in_the_catalog() -> void:
	expect_eq(DirAccess.get_files_at("res://data/hangar/parts").size(), CATALOG.parts.size(), "parts registered")
	expect_eq(DirAccess.get_files_at("res://data/hangar/ships").size(), CATALOG.ships.size(), "ships registered")
	for ship in CATALOG.ships.filter(func(s: ShipDef) -> bool: return not s.tree.is_empty()):
		expect_eq(DirAccess.get_files_at("res://data/hangar/tree/%s" % ship.id).size(), ship.tree.size(), "%s tree registered" % ship.id)


func test_content_is_valid() -> void:
	for def in CATALOG.parts:
		expect_true(def.text != "" and not def.attributes.is_empty(), "%s text and attributes" % def.id)
		var effects: Array[Dictionary] = def.effects.duplicate()
		for a in def.attributes:
			expect_true(int(a["max"]) >= 1 and a["name"] != "" and a["text"] != "", "%s.%s" % [def.id, a["id"]])
			effects.append_array(a["effects"])
		for effect: Dictionary in effects:
			expect_true(UpgradeSystem.BASE_STATS.has(effect["stat"]), "%s: %s" % [def.id, effect["stat"]])
		expect_true(ResourceLoader.exists("res://assets/art/dusk_armada/parts/%s.png" % def.part), "%s part" % def.id)
	for category: String in CATALOG.placement:
		for mount: String in CATALOG.placement[category]:
			for effect: Dictionary in CATALOG.placement[category][mount]:
				expect_true(UpgradeSystem.BASE_STATS.has(effect["stat"]), "placement %s %s" % [category, mount])
	for ship in CATALOG.ships:
		for node in ship.tree:
			expect_true(node.branch in ShipTree.BRANCHES, "%s branch" % node.id)
			for id in node.requires:
				expect_true(ship.node(id) != null, "%s requires %s" % [node.id, id])
			var partner := ship.node(node.excludes) if node.excludes != &"" else null
			expect_true(node.excludes == &"" or (partner != null and partner.excludes == node.id), "%s fork pairs up" % node.id)
			for effect: Dictionary in node.effects:
				expect_true(UpgradeSystem.BASE_STATS.has(effect["stat"]), "%s: %s" % [node.id, effect["stat"]])
	for mount in CATALOG.starter_mounts:
		var def := CATALOG.part(StringName(CATALOG.starter_mounts[mount]))
		expect_true(def != null and CATALOG.ships[0].accepts(StringName(mount), def), "starter on %s" % mount)


func test_new_save_flies_one_of_each_slot() -> void:
	var state := Loadout.default_state(CATALOG)
	var slots: Array[StringName] = []
	for mount in CATALOG.ships[0].mounts:
		var def := Loadout.part_at(CATALOG, state, mount)
		expect_true(def != null, "%s fitted" % mount)
		slots.append(def.slot())
	expect_eq(slots, [&"weapon", &"shield", &"engine", &"extra"], "nose, left, rear, right")
	expect_true(_stats(state)[&"freeze_charges"] == 1, "starter power works")


func test_nose_takes_weapons_and_sides_take_anything() -> void:
	var state := _owning(["twin_cannon", "regen_field", "needle_gun"])
	expect_true(not Loadout.place(CATALOG, state, &"nose", &"regen_field"), "no shield on the nose")
	expect_true(Loadout.place(CATALOG, state, &"nose", &"twin_cannon"), "weapon on the nose")
	expect_eq(_stats(state)[&"extra_shots"], 0, "the second barrel lives in the cannon's WeaponDef")
	expect_true(Loadout.place(CATALOG, state, &"right", &"pulse_laser"), "a second weapon on a side mount")
	expect_true(not Loadout.place(CATALOG, state, &"rear", &"needle_gun"), "but only two weapons")


func test_one_part_per_slot_type() -> void:
	var state := _owning(["regen_field", "vector_jet"])
	expect_true(not Loadout.place(CATALOG, state, &"right", &"regen_field"), "the bubble already fills the shield slot")
	Loadout.place(CATALOG, state, &"left", &"")
	expect_true(Loadout.place(CATALOG, state, &"right", &"regen_field"), "free slot after emptying")
	expect_true(Loadout.place(CATALOG, state, &"rear", &"vector_jet"), "swapping the engine on its own mount")
	expect_true(Loadout.place(CATALOG, state, &"left", &"vector_jet"), "moving a part to another mount")
	expect_eq(String(state["mounts"]["rear"]), "", "moved off the old mount")


func test_placement_changes_handling() -> void:
	var state := Loadout.default_state(CATALOG)
	expect_true(is_equal_approx(_stats(state)[&"strafe_right"], 1.0), "rear engine: no strafe bonus")
	expect_true(_stats(state)[&"move_speed"] > 1.1 * 1.1, "rear engine: straight speed")
	Loadout.place(CATALOG, state, &"left", &"")
	Loadout.place(CATALOG, state, &"left", &"ion_thruster")
	expect_true(is_equal_approx(_stats(state)[&"strafe_right"], 1.25), "left engine pushes right")
	expect_true(is_equal_approx(_stats(state)[&"strafe_left"], 1.0), "but not left")
	Loadout.place(CATALOG, state, &"rear", &"bubble")
	expect_true(is_equal_approx(_stats(state)[&"shield_recharge"], 1.0), "rear shield: normal")
	Loadout.place(CATALOG, state, &"right", &"bubble")
	expect_true(is_equal_approx(_stats(state)[&"shield_recharge"], 0.8), "side shield recharges faster")


func test_attributes_level_up_and_cost_more() -> void:
	var def := CATALOG.part(&"pulse_laser")
	var state := Loadout.default_state(CATALOG)
	expect_eq(_stats(state)[&"damage"], 0, "level 0")
	var first := Loadout.upgrade_price(state, def, &"power")
	Loadout.upgrade(state, def, &"power")
	Loadout.upgrade(state, def, &"power")
	expect_eq(_stats(state)[&"damage"], 2, "two POWER levels")
	expect_true(Loadout.upgrade_price(state, def, &"power") > first, "levels cost more")
	Loadout.upgrade(state, def, &"speed")
	Loadout.upgrade(state, def, &"speed")
	expect_true(is_equal_approx(_stats(state)[&"fire_rate"], 1.2), "SPEED adds 10% per level")
	Loadout.upgrade(state, def, &"power")
	expect_eq(Loadout.upgrade_price(state, def, &"power"), -1, "POWER maxed at 3")
	expect_eq(Loadout.upgrade_price(state, CATALOG.part(&"twin_cannon"), &"power"), -1, "not owned")
	expect_eq(Loadout.look(state, def.id), 2, "5 levels glow")


func test_store_preview_fits_without_touching_the_save() -> void:
	var state := Loadout.default_state(CATALOG)
	var before := state.duplicate(true)
	var cannon := Loadout.preview(CATALOG, state, CATALOG.part(&"twin_cannon"))
	expect_eq(String(cannon["mounts"]["nose"]), "twin_cannon", "weapon previews on the nose")
	var regen := Loadout.preview(CATALOG, state, CATALOG.part(&"regen_field"))
	expect_eq(String(regen["mounts"]["left"]), "regen_field", "swaps the fitted shield")
	expect_eq(state, before, "save untouched")


func test_stock_rotates_unowned_parts() -> void:
	var state := Loadout.default_state(CATALOG)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	HangarStock.roll(CATALOG, state, rng)
	var stock: Array = state["stock"]
	expect_eq(stock.size(), HangarStock.SIZE, "full stock")
	for id: String in stock:
		expect_true(not Loadout.owns(state, StringName(id)), "%s not owned" % id)
		expect_eq(stock.count(id), 1, "%s once" % id)
	state["stock"] = ["twin_cannon", "power_chip", "bubble"]
	var def := CATALOG.part(&"twin_cannon")
	expect_true(HangarStock.take(state, def), "buy from stock")
	expect_true(Loadout.owns(state, def.id) and not HangarStock.in_stock(state, def.id), "owned, gone from stock")
	expect_true(not HangarStock.take(state, CATALOG.part(&"pulse_laser")), "can't buy what isn't stocked")


func test_ship_tree_forks_and_merges() -> void:
	var state := Loadout.default_state(CATALOG)
	var ship := CATALOG.ships[0]
	var n := func(id: StringName) -> TreeNodeDef: return ship.node(id)
	expect_eq(ShipTree.gate(CATALOG, state, n.call(&"rail")), ShipTree.Gate.NEEDS_NODE, "needs the node below")
	for id in [&"focus_lens", &"rail", &"plating"]:
		expect_true(ShipTree.buy(CATALOG, state, n.call(id)), "buy %s" % id)
	expect_true(is_equal_approx(_stats(state)[&"projectile_speed"], 1.3), "node effect applies")
	Loadout.place(CATALOG, state, &"nose", &"")
	expect_true(is_equal_approx(_stats(state)[&"projectile_speed"], 1.3), "belongs to the ship, not a part")
	expect_eq(ShipTree.gate(CATALOG, state, n.call(&"scatter")), ShipTree.Gate.CLOSED, "the fork closes the other side")
	expect_eq(ShipTree.gate(CATALOG, state, n.call(&"ricochet")), ShipTree.Gate.NEEDS_NODE, "a merge needs both parents")
	ShipTree.buy(CATALOG, state, n.call(&"reflect"))
	expect_true(ShipTree.buy(CATALOG, state, n.call(&"ricochet")), "both parents owned")
	expect_eq(ShipTree.gate(CATALOG, state, n.call(&"armada")), ShipTree.Gate.NEEDS_NODE, "a capstone needs two")
	ShipTree.buy(CATALOG, state, n.call(&"afterburn"))
	ShipTree.buy(CATALOG, state, n.call(&"blink"))
	var nose := CATALOG.part(&"pulse_laser")
	var before := Loadout.sockets(CATALOG, state, CATALOG.part(&"ion_thruster")).size()
	ShipTree.buy(CATALOG, state, n.call(&"phase_link"))
	expect_eq(Loadout.sockets(CATALOG, state, CATALOG.part(&"ion_thruster")).size(), before + 1, "socket node adds to engines")
	expect_eq(Loadout.sockets(CATALOG, state, nose), [1], "not to weapons")
	expect_true(ShipTree.buy(CATALOG, state, n.call(&"armada")), "any two open the capstone")
	expect_eq(ShipTree.gate(CATALOG, state, n.call(&"lone_wolf")), ShipTree.Gate.CLOSED, "one capstone only")
	expect_eq(ShipTree.price(state, ship, n.call(&"focus_lens")), n.call(&"focus_lens").cost * 2, "rank 2 costs double")


func test_sockets_grow_with_rarity() -> void:
	expect_eq(PartDef.socket_groups(3, 1), [2, 1], "a linked pair and a single")
	var last := 0
	for def in CATALOG.parts:
		expect_true(def.links * 2 <= def.sockets, "%s links fit" % def.id)
	for tier in PartDef.Tier.values():
		var counts := CATALOG.parts.filter(func(p: PartDef) -> bool: return p.tier == tier).map(func(p: PartDef) -> int: return p.sockets)
		if not counts.is_empty():
			expect_true(counts.min() >= last, "tier %d has at least as many sockets" % tier)
			last = counts.max()


func test_ships_unlock_by_stage() -> void:
	var state := Loadout.default_state(CATALOG)
	expect_eq(CATALOG.ships.size(), 3, "three ships")
	expect_true(Loadout.unlocked(state, CATALOG.ships[0]), "first ship open")
	var talon := CATALOG.ship(&"talon")
	expect_true(not Loadout.unlocked(state, talon), "talon locked")
	state["ship"] = "talon"
	expect_eq(Loadout.normalize(state, CATALOG)["ship"], "kestrel", "a locked ship can't be flown")
	state["cleared"].append(String(talon.unlock_stage))
	state["ship"] = "talon"
	expect_true(Loadout.unlocked(state, talon), "clearing its stage unlocks it")
	expect_eq(Loadout.normalize(state, CATALOG)["ship"], "talon", "and it stays picked")


func test_stat_words() -> void:
	var before := UpgradeSystem.BASE_STATS.duplicate()
	var after := before.duplicate()
	after[&"damage"] = 1
	after[&"shield_recharge"] = 0.9
	expect_eq(StatWords.change([{"stat": &"damage"}], before, after), "Damage 1 → 2")
	expect_eq(StatWords.change([{"stat": &"shield_recharge"}], before, after), "Recharge 12.0s → 10.8s")


func test_old_saves_reset_but_keep_pilots() -> void:
	var state := Loadout.normalize({"frame": "talon", "modules": [], "equipped": [], "pilot": "rook", "pilots": ["vega", "rook"]}, CATALOG)
	expect_eq(state["ship"], "kestrel")
	expect_eq(state["pilot"], "rook")
	expect_true(Loadout.part_at(CATALOG, state, &"nose") != null, "fresh loadout")
	var broken := Loadout.default_state(CATALOG)
	broken["parts"]["gone"] = {}
	broken["mounts"]["rear"] = "gone"
	broken = Loadout.normalize(broken, CATALOG)
	expect_true(not broken["parts"].has("gone") and broken["mounts"]["rear"] == "", "unknown parts dropped")
	var ranked := Loadout.default_state(CATALOG)
	ranked["parts"]["pulse_laser"] = 3
	ranked.erase("stock")
	ranked.erase("tree")
	ranked = Loadout.normalize(ranked, CATALOG)
	expect_eq(ranked["parts"]["pulse_laser"], {}, "ranked parts kept at level 0")
	expect_true(ranked["stock"] is Array and ranked["tree"] is Dictionary, "stock and tree added")


func test_medal_goals() -> void:
	var tracker := MedalTracker.new(_medal(MedalDef.Goal.NO_DAMAGE))
	expect_true(tracker.earned(), "no damage yet")
	tracker.ships_lost = 1
	expect_true(not tracker.earned(), "lost a ship")
	tracker = MedalTracker.new(_medal(MedalDef.Goal.ACCURACY, 0.6))
	expect_true(not tracker.earned(), "no shots fired")
	tracker.shots = 10
	tracker.hits = 6
	expect_true(tracker.earned(), "60% accuracy")
	expect_true(not MedalTracker.new(null).earned(), "stage without medal")


func test_sector_1_stages_have_medals() -> void:
	for stage in (load("res://data/sectors/sector_1.tres") as SectorDef).stages:
		expect_true(stage.medal != null, "%s medal" % stage.id)


func test_pilots() -> void:
	expect_true(CATALOG.pilots.size() >= 2, "pilots registered")
	expect_eq(DirAccess.get_files_at("res://data/hangar/pilots").size(), CATALOG.pilots.size(), "pilot files registered")
	expect_eq(CATALOG.pilots[0].cost, 0, "first pilot is free")
	for pilot in CATALOG.pilots:
		expect_true(pilot.cooldown > 0.0, "%s cooldown" % pilot.id)
		for effect: Dictionary in pilot.effects:
			expect_true(UpgradeSystem.BASE_STATS.has(effect["stat"]), "%s: %s" % [pilot.id, effect["stat"]])
	var state := Loadout.default_state(CATALOG)
	expect_eq(Loadout.pilot_of(CATALOG, state), CATALOG.pilots[0], "new save flies the first pilot")
	state.erase("pilot")
	state.erase("pilots")
	expect_eq(Loadout.pilot_of(CATALOG, Loadout.normalize(state, CATALOG)), CATALOG.pilots[0], "older hangar saves get a pilot")


func test_laser_never_gets_penetration() -> void:
	var def := CATALOG.part(&"pulse_laser")
	expect_true(def.attribute(&"thickness").is_empty(), "no PENETRATION track on the laser")
	expect_eq(def.attributes.size(), 2, "two tracks: POWER and SPEED")
