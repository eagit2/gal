extends TestCase


func test_start_run_resets_state() -> void:
	GameState.score = 999
	GameState.start_run(&"ace", 3)
	expect_eq(GameState.score, 0, "score")
	expect_eq(GameState.lives, 3, "lives")
	expect_eq(GameState.difficulty_id, &"ace", "difficulty")


func test_lose_life_reports_run_over_at_zero() -> void:
	GameState.start_run(&"pilot", 2)
	expect_eq(GameState.lose_life(), false, "first life")
	expect_eq(GameState.lose_life(), true, "last life")
	expect_eq(GameState.lives, 0, "lives")


func test_difficulty_data_loads() -> void:
	for id in ["cadet", "pilot", "ace", "nightmare"]:
		var d: DifficultyDef = load("res://data/difficulty/%s.tres" % id)
		expect_eq(d.id, StringName(id), id)


func test_snapshot_survives_json_and_restores() -> void:
	GameState.start_run(&"ace", 3)
	GameState.score = 1234
	GameState.stage_index = 4
	var run: Dictionary = JSON.parse_string(JSON.stringify(GameState.snapshot()))
	var lives := GameState.lives
	GameState.start_run(&"pilot", 1)
	GameState.restore(run)
	expect_eq(GameState.difficulty_id, &"ace", "difficulty")
	expect_eq(GameState.stage_index, 4, "stage")
	expect_eq(GameState.score, 1234, "score")
	expect_eq(GameState.lives, lives, "lives")


func test_title_lists_difficulties_easiest_first() -> void:
	var ids: Array[StringName] = []
	for def in preload("res://scenes/main/title.gd").load_difficulties():
		ids.append(def.id)
	expect_eq(ids, [&"cadet", &"pilot", &"ace", &"nightmare"] as Array[StringName], "order")


func test_dev_options_set_only_when_given() -> void:
	expect_eq(DevOptions.parse(PackedStringArray()).is_set(), false, "empty")
	expect_eq(DevOptions.parse(PackedStringArray(["god=1"])).is_set(), true, "god")
