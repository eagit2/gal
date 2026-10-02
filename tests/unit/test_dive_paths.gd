extends TestCase


func test_dive_starts_at_enemy_and_ends_below_screen() -> void:
	var start := Vector2(200, 250)
	var curve := DivePaths.build(start, Vector2(300, 860), [] as Array[StringName])
	expect_eq(curve.get_point_position(0), start, "start")
	expect_true(curve.get_point_position(curve.point_count - 1).y > 960.0, "ends off screen")


func test_dive_stays_inside_horizontal_bounds() -> void:
	var curve := DivePaths.build(Vector2(40, 200), Vector2(20, 860), [&"zigzag", &"wide"] as Array[StringName])
	for i in curve.point_count:
		var x := curve.get_point_position(i).x
		expect_true(x >= DivePaths.MIN_X and x <= DivePaths.MAX_X, "point %d x=%f" % [i, x])
