extends TestCase
## Scatter body, leaf shield and multi-part: layout math and that their rows carry the traits.


func test_scatter_lanes_are_a_permutation() -> void:
	for n in [12, 8, 7, 6]:
		var seen := {}
		for i in n:
			var x := ScatterBodyTrait.lane_x(i, n)
			expect_true(x >= 60.0 and x <= 480.0, "lane in range")
			seen[snappedf(x, 0.01)] = true
		expect_eq(seen.size(), n, "every lane used once for %d" % n)


func test_scatter_grid_is_centered() -> void:
	var sum := Vector2.ZERO
	for i in 12:
		sum += ScatterBodyTrait.grid_offset(i, 12)
	expect_true(sum.length() < 0.01, "grid centered")


func test_leaf_orbit() -> void:
	var p := LeafShieldTrait.orbit_pos(Vector2(100, 100), 60.0, 0.0, 0, 6)
	expect_true(p.is_equal_approx(Vector2(160, 100)), "first leaf east")
	var q := LeafShieldTrait.orbit_pos(Vector2(100, 100), 60.0, 0.0, 3, 6)
	expect_true(q.is_equal_approx(Vector2(40, 100)), "opposite leaf west")


func test_multi_part_rates() -> void:
	expect_true(MultiPartTrait.rate_for(0) < MultiPartTrait.rate_for(2), "survivors speed up")
	expect_true(MultiPartTrait.part_offset(0, 3).x < 0.0 and MultiPartTrait.part_offset(2, 3).x > 0.0, "spread")


func test_rows_carry_the_traits() -> void:
	expect_true(Roster.elite(&"wood_leaf").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is LeafShieldTrait), "wood_leaf")
	expect_true(Roster.elite(&"yellow_devil").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is ScatterBodyTrait), "yellow_devil")
	expect_true(Roster.elite(&"wily_machine").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is MultiPartTrait), "wily_machine")
