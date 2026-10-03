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
	for ship in CATALOG.ships:
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
			expect_true(node.mount == &"hull" or node.mount in ship.mounts, "%s mount" % node.id)
			expect_true(node.requires == &"" or ship.node(node.requires) != null, "%s requires" % node.id)
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
	expect_eq(slots, [&"weapon", &"shield", &"bonus", &"power"], "nose, left, rear, right")
	expect_true(_stats(state)[&"freeze_charges"] == 1, "starter power works")


func test_weapons_only_on_the_nose() -> void:
	var state := _owning(["twin_cannon", "regen_field"])
	expect_true(not Loadout.place(CATALOG, state, &"left", &"twin_cannon"), "no weapon on a side mount")
	expect_true(not Loadout.place(CATALOG, state, &"nose", &"regen_field"), "no shield on the nose")
	expect_true(Loadout.place(CATALOG, state, &"nose", &"twin_cannon"), "weapon on the nose")
	expect_eq(_stats(state)[&"extra_shots"], 1)


func test_one_part_per_slot_type() -> void:
	var state := _owning(["regen_field", "vector_jet"])
	expect_true(not Loadout.place(CATALOG, state, &"right", &"regen_field"), "the bubble already fills the shield slot")
	Loadout.place(CATALOG, state, &"left", &"")
	expect_true(Loadout.place(CATALOG, state, &"right", &"regen_field"), "free slot after emptying")
	expect_true(Loadout.place(CATALOG, state, &"rear", &"vector_jet"), "swapping the bonus part on its own mount")
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
	expect_true(is_equal_approx(_stats(state)[&"fire_rate"], 1.21), "SPEED multiplies per level")
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
	var def := CATALOG.part(StringName(stock[0]))
	expect_true(HangarStock.take(state, def), "buy from stock")
	expect_true(Loadout.owns(state, def.id) and not HangarStock.in_stock(state, def.id), "owned, gone from stock")
	expect_true(not HangarStock.take(state, CATALOG.part(&"pulse_laser")), "can't buy what isn't stocked")


func test_part_rarity_gates_the_blueprint() -> void:
	var state := _owning(["missile_pod"])
	var ship := CATALOG.ships[0]
	var lens := ship.node(&"focus_lens")
	var coil := ship.node(&"rail_coil")
	expect_eq(ShipTree.gate(CATALOG, state, coil), ShipTree.Gate.NEEDS_NODE, "needs its parent")
	expect_true(ShipTree.buy(CATALOG, state, lens), "starter node opens with the starter laser")
	expect_eq(ShipTree.gate(CATALOG, state, coil), ShipTree.Gate.NEEDS_PART, "uncommon node needs a rarer nose part")
	Loadout.place(CATALOG, state, &"nose", &"missile_pod")
	expect_true(ShipTree.buy(CATALOG, state, coil), "rare missile pod opens it")
	expect_true(is_equal_approx(_stats(state)[&"projectile_speed"], 1.1), "node effect applies")
	Loadout.place(CATALOG, state, &"nose", &"pulse_laser")
	expect_true(is_equal_approx(_stats(state)[&"projectile_speed"], 1.0), "goes dark with a starter part")
	expect_true(is_equal_approx(_stats(state)[&"fire_rate"], 1.05), "starter node stays lit")
	expect_eq(ShipTree.price(state, ship, lens), lens.cost * 2, "rank 2 costs double")


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
