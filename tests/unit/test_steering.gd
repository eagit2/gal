extends TestCase


func test_turn_is_limited_by_max_angle() -> void:
	var v := Steering.turn(Vector2.DOWN * 100.0, Vector2.RIGHT, 0.5, 200.0)
	expect_true(absf(Vector2.DOWN.angle_to(v) - (-0.5)) < 0.001, "turned 0.5 rad toward right: %s" % v)
	expect_true(absf(v.length() - 200.0) < 0.01, "speed applied")


func test_turn_snaps_when_within_limit() -> void:
	var v := Steering.turn(Vector2.DOWN, Vector2(0.1, 1.0), 1.0, 50.0)
	expect_true(v.normalized().is_equal_approx(Vector2(0.1, 1.0).normalized()), "aligned")


func test_separation_pushes_away_from_close_neighbours() -> void:
	var others: Array[Vector2] = [Vector2(10, 0), Vector2(200, 0)]
	var push := Steering.separation(Vector2.ZERO, others, 34.0)
	expect_true(push.x < 0.0 and is_zero_approx(push.y), "pushed left only: %s" % push)
