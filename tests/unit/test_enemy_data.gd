extends TestCase
## Every enemy has a brain, and pacing values stay in sane ranges.


func test_every_enemy_has_a_brain() -> void:
	for file in DirAccess.get_files_at("res://data/enemies"):
		if file.ends_with(".tres"):
			var def: EnemyDef = load("res://data/enemies/" + file)
			expect_true(def.brain != null, "%s has a brain" % file)


func test_max_attackers_scale_with_pressure() -> void:
	expect_eq(DiveController.max_attackers_for(0.6, 1.0), 3, "cadet floor")
	expect_eq(DiveController.max_attackers_for(1.0, 1.0), 4, "pilot stage 1")
	expect_eq(DiveController.max_attackers_for(1.6, 2.0), 12, "nightmare cap")


func test_free_slots_skip_occupied() -> void:
	var occupied: Array[Vector2i] = [Vector2i(0, 0), Vector2i(9, 4)]
	var free := StageRunner.free_slots(occupied)
	expect_eq(free.size(), Formation.COLUMNS * Formation.ROWS - 2, "count")
	expect_true(Vector2i(0, 0) not in free and Vector2i(1, 0) in free, "contents")


func test_difficulty_shield_recharge_rises_with_difficulty() -> void:
	var cadet: DifficultyDef = load("res://data/difficulty/cadet.tres")
	var nightmare: DifficultyDef = load("res://data/difficulty/nightmare.tres")
	expect_true(cadet.shield_recharge < nightmare.shield_recharge, "recharge")
