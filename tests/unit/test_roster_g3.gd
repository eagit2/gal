extends TestCase
## Pure logic of the G3 roster traits (gravity pool, blade release, orbit guard, decoy, rock swing).


func test_pool_bends_shots_toward_center() -> void:
	var v := GravityPool.bend(Vector2(0, -400), Vector2(100, 0), Vector2(0, 0), 420.0, 0.1)
	expect_true(v.x < 0.0 and is_equal_approx(v.y, -400.0), "pulled left only")


func test_pool_drift_stops_at_center() -> void:
	expect_eq(GravityPool.drift(Vector2(10, 0), Vector2.ZERO, 140.0, 1.0), Vector2.ZERO, "no overshoot")
	expect_true(GravityPool.drift(Vector2(100, 0), Vector2.ZERO, 140.0, 0.1).is_equal_approx(Vector2(86, 0)), "moves 14px")


func test_blade_thresholds() -> void:
	expect_eq(BladeReleaseTrait.thresholds_passed(1.0, 0.33, 0), 0, "full hp")
	expect_eq(BladeReleaseTrait.thresholds_passed(0.66, 0.33, 0), 1, "first third")
	expect_eq(BladeReleaseTrait.thresholds_passed(0.30, 0.33, 0), 2, "two at once")
	expect_eq(BladeReleaseTrait.thresholds_passed(0.30, 0.33, 2), 0, "no repeats")
	expect_eq(BladeReleaseTrait.thresholds_passed(0.005, 0.33, 2), 1, "third release near death")


func test_orbit_slots_spread_evenly() -> void:
	var a := OrbitGuardTrait.slot_position(0, 4, 0.0, 70.0)
	var b := OrbitGuardTrait.slot_position(2, 4, 0.0, 70.0)
	expect_true(a.is_equal_approx(-b) and is_equal_approx(a.length(), 70.0), "opposite slots")


func test_decoy_copy_positions() -> void:
	expect_true(is_equal_approx(DecoyCopy.copy_x(100.0, 0, 70.0, 470.0), 440.0), "mirrored")
	expect_true(is_equal_approx(DecoyCopy.copy_x(270.0, 1, 70.0, 470.0), 470.0), "tent peak")
	expect_true(is_equal_approx(DecoyCopy.copy_x(270.0, 2, 70.0, 470.0), 70.0), "opposite tent")


func test_swing_angle() -> void:
	expect_true(is_equal_approx(TowedRock.swing_angle_at(0.0, 2.2, 2.4), 0.0), "starts straight down")
	var peak := 0.0
	for i in 400:
		peak = maxf(peak, absf(TowedRock.swing_angle_at(i * 0.01, 2.2, 2.4)))
	expect_true(peak <= 1.2 + 0.001 and peak > 1.1, "reaches half the arc each way")


func test_rows_carry_traits() -> void:
	expect_true(Roster.elite(&"gravity_well").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is GravityPoolTrait), "gravity_well")
	expect_true(Roster.elite(&"orbiter").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is OrbitGuardTrait), "orbiter")
	expect_true(Roster.elite(&"mirage").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is DecoyTrait), "mirage")
	expect_true(Roster.elite(&"hive_carrier").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is BladeReleaseTrait), "carrier")
	var tow: RockTowTrait = Roster.elite(&"rock_hauler").traits_for_phase(0).filter(func(t: EliteTrait) -> bool: return t is RockTowTrait)[0]
	expect_true(is_equal_approx(tow.tether_length, 250.0) and is_equal_approx(tow.swing_after, 3.0), "rock hauler")
