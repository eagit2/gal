extends TestCase
## Roster traits fire_bar, slot_jam, evolve, flagship and scrap_thief.


func test_rows_carry_their_traits() -> void:
	expect_true(Roster.enemy(&"fire_breather").traits[0] is FireBarTrait, "fire_breather")
	expect_true(Roster.enemy(&"jammer").traits[0] is SlotJamTrait, "jammer")
	expect_true(Roster.enemy(&"evolver").traits[0] is EvolveTrait, "evolver")
	expect_true(Roster.enemy(&"flagship").traits[0] is FlagshipTrait, "flagship")
	expect_true(Roster.enemy(&"scrap_thief").traits[0] is ScrapThiefTrait, "scrap_thief")


func test_fire_bar_meanders() -> void:
	var straight := FireBar.segment_offset(2, 0.0, 0.0, 18.0, 24.0, 3.0)
	expect_true(is_equal_approx(straight.x, 54.0), "along the bar")
	var later := FireBar.segment_offset(2, 0.0, 1.0, 18.0, 24.0, 3.0)
	expect_true(absf(later.y - straight.y) > 1.0, "sideways sway changes with time")
	expect_true(absf(later.y) <= 24.0, "sway is bounded by wobble")


func test_beam_hits_only_inside_the_width() -> void:
	var o := Vector2(100, 100)
	expect_true(SlotJamTrait.beam_hits(o, Vector2.DOWN, Vector2(110, 500), 28.0), "inside")
	expect_true(not SlotJamTrait.beam_hits(o, Vector2.DOWN, Vector2(130, 500), 28.0), "outside")
	expect_true(not SlotJamTrait.beam_hits(o, Vector2.DOWN, Vector2(100, 0), 28.0), "behind the emitter")


func test_evolve_glow() -> void:
	expect_eq(EvolveTrait.glow_fraction(7.0, 8.0, 1.5), 0.0, "not yet")
	expect_true(is_equal_approx(EvolveTrait.glow_fraction(8.75, 8.0, 1.5), 0.5), "halfway")
	expect_eq(EvolveTrait.glow_fraction(20.0, 8.0, 1.5), 1.0, "done")


func test_flagship_squad() -> void:
	expect_true(FlagshipTrait.escort_offset(0).x < 0.0 and FlagshipTrait.escort_offset(1).x > 0.0, "alternate sides")
	expect_true(FlagshipTrait.earns_bonus(2, 0), "all escorts dead")
	expect_true(not FlagshipTrait.earns_bonus(2, 1), "one left")
	expect_true(not FlagshipTrait.earns_bonus(0, 0), "never led any")


func test_scrap_thief_math() -> void:
	expect_eq(ScrapThiefTrait.payout(10, 1.5), 15, "payback")
	expect_eq(ScrapThiefTrait.take_amount(8, 15, 20), 5, "capped")
	expect_eq(ScrapThiefTrait.take_amount(3, 0, 20), 3, "whole pile")
	expect_eq(ScrapThiefTrait.take_amount(3, 20, 20), 0, "full")
