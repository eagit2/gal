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
