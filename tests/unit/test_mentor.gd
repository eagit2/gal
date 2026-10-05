extends TestCase
## Stage 18 mentor cutscene rules (MentorRules, CutsceneDef).

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")
const DEF: CutsceneDef = preload("res://data/cutscenes/stage18_mentor.tres")


func _state() -> Dictionary:
	var state := Loadout.default_state(CATALOG)
	state["parts"]["twin_cannon"] = {}
	state["mounts"]["nose"] = "twin_cannon"
	return state


func test_plays_after_three_deaths_in_a_row() -> void:
	var m := MentorRules.fresh()
	for i in 2:
		MentorRules.died(m, &"stage_18", DEF)
	MentorRules.died(m, &"stage_17", DEF)
	expect_true(not MentorRules.wants_intro(m, &"stage_18", DEF), "two deaths on 18 are not enough")
	MentorRules.cleared(m, &"stage_18", DEF)
	expect_eq(m["deaths"], 0, "a clear resets the streak")
	for i in 3:
		MentorRules.died(m, &"stage_18", DEF)
	expect_true(MentorRules.wants_intro(m, &"stage_18", DEF), "three in a row")
	expect_true(not MentorRules.wants_intro(m, &"stage_19", DEF), "only on stage 18")


func test_lend_fits_a_max_needle_with_locked_combo() -> void:
	var state := _state()
	var m := MentorRules.fresh()
	MentorRules.grant(CATALOG, state, m, DEF)
	expect_eq(state["mounts"]["nose"], "mentor_needle", "fitted on the nose")
	expect_eq(m["replaced"], "twin_cannon", "remembers the old gun")
	expect_eq(state["parts"]["mentor_needle"], {"fire_rate": 5, "pierce": 3}, "max levels")
	var part := CATALOG.part(&"mentor_needle")
	expect_eq(Loadout.chips_in(CATALOG, state, part), ["volt_chip", "seeker_chip"] as Array[String], "volt and seeker")
	expect_eq(Loadout.part_combos(CATALOG, state, part)[0].id, &"thunder_seeker", "thunder seeker combo")
	expect_true(not Loadout.set_chip(CATALOG, state, part, 0, &""), "chips are locked")
	expect_true(not MentorRules.wants_intro(m, &"stage_18", DEF), "plays once")


func test_take_back_refits_the_old_gun_and_leaves_ember() -> void:
	var state := _state()
	state["chips"]["volt_chip"] = 2
	var m := MentorRules.fresh()
	MentorRules.grant(CATALOG, state, m, DEF)
	expect_true(MentorRules.wants_take_back(m, &"stage_18", DEF), "due after a clear")
	MentorRules.take_back(state, m, DEF)
	expect_true(not Loadout.owns(state, &"mentor_needle"), "needle gone")
	expect_eq(state["mounts"]["nose"], "twin_cannon", "old gun back on")
	expect_eq(state["chips"]["ember_chip"], 1, "an ember chip")
	expect_eq(state["chips"]["volt_chip"], 2, "own chips untouched")
	expect_true(not MentorRules.wants_take_back(m, &"stage_18", DEF), "done for good")
	expect_true(not MentorRules.wants_intro(m, &"stage_18", DEF), "never again")


func test_take_back_lines() -> void:
	var m := MentorRules.fresh()
	MentorRules.grant(CATALOG, _state(), m, DEF)
	MentorRules.stage_started(m, &"stage_18", DEF)
	expect_eq(MentorRules.take_back_line(m, DEF), "Settle down big shot", "clean first try")
	MentorRules.struck(m, &"stage_18", DEF)
	expect_eq(MentorRules.take_back_line(m, DEF), DEF.line_fallback, "hit")
	MentorRules.stage_started(m, &"stage_18", DEF)
	expect_eq(MentorRules.take_back_line(m, DEF), "Top Gun called, they want their fighter jet back", "clean after dying")
	MentorRules.struck(m, &"stage_18", DEF)
	expect_eq(MentorRules.take_back_line(m, DEF), DEF.line_fallback, "any other clear")


func test_record_lives_in_the_save() -> void:
	var data := {}
	var m := MentorRules.record(data, DEF)
	m["deaths"] = 2
	expect_eq(MentorRules.record(data, DEF)["deaths"], 2, "same record")
