extends TestCase
## Hangar loadout rules (slots, links, levels, mastery, chains) and medal goals.

const CATALOG: ModuleCatalog = preload("res://data/hangar/catalog.tres")


func _state(frame: StringName, ids: Array) -> Dictionary:
	var state := Loadout.default_state(CATALOG)
	state["modules"] = []
	for id: String in ids:
		state["modules"].append({"id": id, "ap": 0, "born": false})
	Loadout.set_frame(CATALOG, state, frame)
	return state


func _stats(state: Dictionary) -> Dictionary:
	return UpgradeSystem.compute([], [], Loadout.effects(CATALOG, state))


func _medal(goal: MedalDef.Goal, target := 0.0) -> MedalDef:
	var medal := MedalDef.new()
	medal.goal = goal
	medal.target = target
	return medal


func test_every_file_is_in_the_catalog() -> void:
	expect_eq(DirAccess.get_files_at("res://data/hangar/modules").size(), CATALOG.modules.size(), "modules registered")
	expect_eq(DirAccess.get_files_at("res://data/hangar/frames").size(), CATALOG.frames.size(), "frames registered")


func test_content_is_valid() -> void:
	for def in CATALOG.modules:
		for effect: Dictionary in def.effects + def.per_level:
			expect_true(UpgradeSystem.BASE_STATS.has(effect["stat"]), "%s: %s" % [def.id, effect["stat"]])
		expect_true(def.requires_mastered == &"" or CATALOG.module(def.requires_mastered) != null, "%s chain" % def.id)
		expect_true(ResourceLoader.exists("res://assets/art/dusk_armada/parts/%s.png" % def.part), "%s part" % def.id)
	for frame in CATALOG.frames:
		expect_true(frame.pairs * 2 <= frame.slots, "%s pairs fit" % frame.id)
	for id in CATALOG.starter_modules:
		expect_true(CATALOG.module(id) != null, "starter %s" % id)


func test_levels_from_ap() -> void:
	var def := CATALOG.module(&"twin_cannon")
	expect_eq(def.level_for(0), 1)
	expect_eq(def.level_for(def.ap_levels[0]), 2)
	expect_eq(def.level_for(99999), def.max_level())


func test_equipped_modules_give_stats_and_levels_stack() -> void:
	var state := _state(&"kestrel", ["twin_cannon"])
	expect_eq(_stats(state)[&"extra_shots"], 0, "owned but not equipped")
	Loadout.equip(state, 2, 0)
	expect_eq(_stats(state)[&"extra_shots"], 1, "equipped")
	state["modules"][0]["ap"] = 99999
	expect_true(is_equal_approx(_stats(state)[&"fire_rate"], 1.05 * 1.05), "two levels above 1")


func test_support_needs_a_link() -> void:
	var state := _state(&"kestrel", ["seeker", "twin_cannon", "magnet_coil"])
	Loadout.equip(state, 0, 0)
	expect_eq(_stats(state)[&"homing"], 0.0, "seeker alone does nothing")
	Loadout.equip(state, 1, 2)
	expect_eq(_stats(state)[&"homing"], 0.0, "seeker needs a weapon partner")
	Loadout.equip(state, 1, 1)
	expect_eq(_stats(state)[&"homing"], 1.5, "linked to a weapon")
	Loadout.equip(state, 2, 0)
	expect_eq(_stats(state)[&"homing"], 0.0, "slot 3 has no partner on Kestrel")


func test_amplifier_raises_partner_level() -> void:
	var state := _state(&"kestrel", ["amplifier", "twin_cannon"])
	Loadout.equip(state, 0, 0)
	Loadout.equip(state, 1, 1)
	expect_eq(Loadout.slot_level(CATALOG, state, 1), 2)
	expect_true(is_equal_approx(_stats(state)[&"fire_rate"], 1.05), "level 2 effects")


func test_equip_moves_a_module_and_frames_trim_slots() -> void:
	var state := _state(&"seraph", ["thrusters"])
	Loadout.equip(state, 5, 0)
	Loadout.equip(state, 0, 0)
	expect_eq(state["equipped"][5], -1, "moved out of slot 6")
	Loadout.equip(state, 5, 0)
	Loadout.set_frame(CATALOG, state, &"kestrel")
	expect_eq(state["equipped"][5], -1, "slot 6 cleared on a 3-slot frame")


func test_mastery_spawns_a_copy_once_and_unlocks_chain() -> void:
	var state := _state(&"kestrel", ["twin_cannon"])
	Loadout.equip(state, 0, 0)
	var spread := CATALOG.module(&"spread_cannon")
	expect_true(not Loadout.in_shop(CATALOG, state, spread), "chain locked")
	var mastered := Loadout.add_ap(CATALOG, state, 500)
	expect_eq(mastered.size(), 1)
	expect_eq((state["modules"] as Array).size(), 2, "copy spawned")
	expect_true(Loadout.in_shop(CATALOG, state, spread), "chain unlocked")
	Loadout.add_ap(CATALOG, state, 500)
	expect_eq((state["modules"] as Array).size(), 2, "only once")


func test_old_saves_reset() -> void:
	var state := Loadout.normalize({"thruster_tuning": 2}, CATALOG)
	expect_eq(state["frame"], "kestrel")
	expect_eq((state["modules"] as Array).size(), CATALOG.starter_modules.size())


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
