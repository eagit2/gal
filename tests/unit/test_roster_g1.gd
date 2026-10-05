extends TestCase
## Roster traits group G1: blade_slash, hard_hat, boomerang, wind_gust, spawner_pipe.


func test_rows_carry_their_traits() -> void:
	var expected := {
		&"blade_diver": BladeSlashTrait,
		&"met": HardHatTrait,
		&"gust": WindGustTrait,
		&"boomeranger": BoomerangTrait,
		&"spawner_pod": SpawnerPipeTrait,
	}
	for id: StringName in expected:
		var def := Roster.enemy(id)
		var found := false
		for t in def.all_traits():
			found = found or is_instance_of(t, expected[id])
		expect_true(found, "%s has its trait" % id)


func test_slash_ends_past_the_locked_spot() -> void:
	var end := BladeSlashTrait.slash_end(Vector2(100, 100), Vector2(100, 400), 120.0)
	expect_true(end.is_equal_approx(Vector2(100, 520)), "overshoots along the line")
	expect_true(BladeSlashTrait.slash_end(Vector2(5, 5), Vector2(5, 5), 50.0).is_equal_approx(Vector2(5, 55)), "no direction falls back to down")


func test_spread_is_centered() -> void:
	var offsets := HardHatTrait.spread_offsets(3, 30.0)
	expect_eq(offsets, [-30.0, 0.0, 30.0] as Array[float], "three way")
	expect_eq(BoomerangTrait.fan_offsets(2, 22.0), [-11.0, 11.0] as Array[float], "two way")


func test_wind_is_clamped_to_the_play_area() -> void:
	expect_true(is_equal_approx(WindGustTrait.pushed_x(100.0, 1.0, 160.0, 0.5, 28.0, 512.0), 180.0), "pushes right")
	expect_true(is_equal_approx(WindGustTrait.pushed_x(30.0, -1.0, 160.0, 0.5, 28.0, 512.0), 28.0), "stops at the wall")


func test_pod_stops_at_the_cap() -> void:
	expect_true(SpawnerPipeTrait.can_spawn(3, 4), "room for one more")
	expect_true(not SpawnerPipeTrait.can_spawn(4, 4), "full")


func test_boomerang_curve_rate_sweeps_the_leg() -> void:
	# 220 px at 300 px/s takes 0.733 s; the turn rate times that is the sweep.
	expect_true(is_equal_approx(BoomerangShot.curve_rate(220.0, 300.0, 1.7) * 220.0 / 300.0, 1.7), "sweep")


func test_met_ducks_only_while_watching() -> void:
	var W := HardHatTrait.Mode.WATCH
	expect_eq(HardHatTrait.next_mode(W, 1.0, true, 2.0, 1.2, 1.0), [HardHatTrait.Mode.HIDE, 1.0], "sees a shot and ducks")
	expect_eq(HardHatTrait.next_mode(HardHatTrait.Mode.AWAY, 0.5, true, 2.0, 1.2, 1.0), [HardHatTrait.Mode.AWAY, 0.5], "looking away, open to fire")
	expect_eq(HardHatTrait.next_mode(W, 0.0, false, 2.0, 1.2, 1.0), [HardHatTrait.Mode.AWAY, 1.2], "looks away after watching")
	expect_eq(HardHatTrait.next_mode(HardHatTrait.Mode.HIDE, 0.0, true, 2.0, 1.2, 1.0), [W, 2.0], "pops back up to watch")
