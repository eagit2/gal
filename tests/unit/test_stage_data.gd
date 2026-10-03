extends TestCase
## Stage data sanity: slots unique and on the grid, challenge stages have none.


func test_sector_stages_load() -> void:
	var sector: SectorDef = load("res://data/sectors/sector_1.tres")
	expect_eq(sector.stages.size(), 3, "stage count")


func test_formation_stages_fill_unique_slots() -> void:
	for id in ["stage_1", "stage_2"]:
		var stage: StageDef = load("res://data/stages/%s.tres" % id)
		var queue := StageRunner.build_queue(stage)
		expect_eq(queue.size(), 40, "%s enemy count" % id)
		var seen := {}
		for entry in queue:
			var slot: Vector2i = entry["slot"]
			expect_true(slot.x >= 0 and slot.x < Formation.COLUMNS and slot.y >= 0 and slot.y < Formation.ROWS, "%s slot %s on grid" % [id, slot])
			expect_true(not seen.has(slot), "%s slot %s unique" % [id, slot])
			seen[slot] = true


func test_challenge_stage_has_no_slots() -> void:
	var stage: StageDef = load("res://data/stages/challenge_1.tres")
	expect_true(stage.is_challenge, "is challenge")
	expect_eq(stage.style, &"outrun_grid", "forces outrun style")
	for entry in StageRunner.build_queue(stage):
		expect_eq(entry["slot"], Vector2i(-1, -1), "no slot")


func test_every_enemy_has_a_visual() -> void:
	for id in ["bee", "moth", "warden"]:
		var def: EnemyDef = load("res://data/enemies/%s.tres" % id)
		expect_true(def.visual_scene != null, id)
