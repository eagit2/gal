extends TestCase
## Elite levels (data/roster/elite_levels.csv): the sheet loads, levels roll by stage, and a
## higher level scales an elite's trait settings.


func test_five_levels_load() -> void:
	expect_eq(Roster.levels.size(), 5, "levels")
	expect_true(Roster.levels[1].hp == 1.0 and Roster.levels[4].hp > Roster.levels[2].hp, "hp grows")


func test_level_rolls_follow_the_stage() -> void:
	for roll in [0.0, 0.5, 0.99]:
		expect_eq(Roster.level_for(1, roll).level, 1, "stage 1 only rolls level 1")
	expect_eq(Roster.level_for(7, 0.99).level, 2, "stage 7 opens level 2")
	expect_eq(Roster.level_for(20, 0.99).level, 5, "stage 20 opens level 5")
	expect_eq(Roster.level_number(9).level, 5, "dev level clamps")


func test_scaled_trait_settings() -> void:
	var base := FrostShellTrait.new()
	var tougher := base.scaled(2.0, 3.0) as FrostShellTrait
	expect_eq(tougher.layers, base.layers * 2, "counts scale with perk")
	expect_eq(tougher.layer_hp, base.layer_hp * 3, "hp settings scale with level hp")
	expect_true(is_equal_approx(tougher.regrow_delay, base.regrow_delay / 2.0), "waits shrink")
	expect_true(base.scaled(1.0, 1.0) == base, "level 1 keeps the same resource")
	expect_true(base.scaled(2.0, 3.0) == tougher, "same level shares one copy")


## Twins write their partner's state; both must key it on the same trait copy, or every new twin
## spawns another one forever (stage 6 freeze, V38).
func test_twins_share_state_above_level_1() -> void:
	var base := TwinTrait.new()
	var a := base.scaled(1.25, 1.5)
	var b := base.scaled(1.25, 1.5)
	expect_true(a == b, "one copy per level")


func test_dev_level_option() -> void:
	expect_eq(DevOptions.parse(PackedStringArray(["level=3"])).level, 3, "level=3")


## Lanes must still fit at the top level, or the lane picker could never finish (froze the game).
func test_meteor_lanes_fit_at_level_5() -> void:
	var base := MeteorCallTrait.new()
	var top := base.scaled(1.75, 2.6) as MeteorCallTrait
	expect_true(is_equal_approx(top.lane_width, base.lane_width), "lane width stays put")
	var fit := floori((540.0 - 2.0 * top.lane_width) / (top.lane_width * 1.6)) + 1
	expect_true(top.lanes <= fit, "%d lanes fit" % top.lanes)
