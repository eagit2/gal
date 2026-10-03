extends TestCase


func test_parse_url_query() -> void:
	var opts := DevOptions.parse(PackedStringArray(["stage=3", "god=1", "repeat", "difficulty=Ace"]))
	expect_eq(opts.stage, "3", "stage")
	expect_eq(opts.god, true, "god")
	expect_eq(opts.repeat, true, "repeat")
	expect_eq(opts.difficulty, &"ace", "difficulty")


func test_defaults_when_empty() -> void:
	var opts := DevOptions.parse(PackedStringArray())
	expect_eq(opts.god, false, "god")
	expect_eq(opts.repeat, false, "repeat")
	var sector: SectorDef = load("res://data/sectors/sector_1.tres")
	expect_eq(opts.stage_index(sector.stages, 0), 0, "fallback")


func test_stage_by_number_or_id() -> void:
	var sector: SectorDef = load("res://data/sectors/sector_1.tres")
	expect_eq(DevOptions.parse(PackedStringArray(["--stage=2"])).stage_index(sector.stages, 0), 1, "number")
	expect_eq(DevOptions.parse(PackedStringArray(["stage=stage_2"])).stage_index(sector.stages, 0), 1, "id")
	expect_eq(DevOptions.parse(PackedStringArray(["stage=nope"])).stage_index(sector.stages, 0), 0, "unknown")


func test_parse_elite_and_capture() -> void:
	var opts := DevOptions.parse(PackedStringArray(["elite=Rock_Hauler", "capture=1"]))
	expect_eq(opts.elite, &"rock_hauler", "elite")
	expect_eq(opts.capture, true, "capture")
	expect_eq(opts.is_set(), true, "dev run")
