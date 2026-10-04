extends TestCase
## Elite levels (data/roster/elite_levels.csv): the sheet loads, levels roll by stage, and a
## higher level scales an elite's trait settings.


func test_four_levels_load() -> void:
	expect_eq(Roster.levels.size(), 4, "levels")
	expect_true(Roster.levels[0].hp == 1.0 and Roster.levels[3].hp > Roster.levels[1].hp, "hp grows")


func test_level_rolls_follow_the_stage() -> void:
	for roll in [0.0, 0.5, 0.99]:
		expect_eq(Roster.level_for(1, roll).level, 1, "stage 1 only rolls level 1")
	expect_eq(Roster.level_for(4, 0.99).level, 2, "stage 4 opens level 2")
	expect_eq(Roster.level_for(20, 0.99).level, 4, "stage 20 opens level 4")
	expect_eq(Roster.level_number(9).level, 4, "dev level clamps")


func test_scaled_trait_settings() -> void:
	var base := FrostShellTrait.new()
	var tougher := base.scaled(2.0, 3.0) as FrostShellTrait
	expect_eq(tougher.layers, base.layers * 2, "counts scale with perk")
	expect_eq(tougher.layer_hp, base.layer_hp * 3, "hp settings scale with level hp")
	expect_true(is_equal_approx(tougher.regrow_delay, base.regrow_delay / 2.0), "waits shrink")
	expect_true(base.scaled(1.0, 1.0) == base, "level 1 keeps the same resource")


func test_dev_level_option() -> void:
	expect_eq(DevOptions.parse(PackedStringArray(["level=3"])).level, 3, "level=3")
