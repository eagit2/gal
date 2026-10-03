extends TestCase
## Upgrade bubbles, Overkill/Chain combo data, and the companion drone's target pick.


func test_combo_bubbles_fall_twice_as_fast() -> void:
	expect_eq(BubbleSystem.fall_speed(false), Pickup.FALL_SPEED)
	expect_eq(BubbleSystem.fall_speed(true), Pickup.FALL_SPEED * 2.0)


func test_overkill_every_30_kills() -> void:
	var combo: ComboDef = load("res://data/combos/overdrive.tres")
	expect_eq(combo.display_name, "OVERKILL")
	expect_eq(combo.threshold, 30.0)
	expect_eq(combo.decay_rate, 0.0)


func test_chain_combo_arcs_to_five() -> void:
	var combo: ComboDef = load("res://data/combos/lock_on.tres")
	expect_eq(combo.threshold, 30.0)
	var stats := UpgradeSystem.compute(combo.effects)
	expect_eq(int(stats[&"chain"]), 5)
	expect_true(int(stats[&"chain"]) >= StatusEffects.BIG_CHAIN, "big lightning")


func test_drone_rams_closest_threat_above_ship() -> void:
	var ship := Vector2(270, 880)
	var points: Array[Vector2] = [Vector2(270, 600), Vector2(300, 800), Vector2(250, 840), Vector2(270, 960)]
	expect_eq(CompanionDrone.pick_target(ship, points, 150.0), 2)
	var far: Array[Vector2] = [Vector2(270, 500)]
	expect_eq(CompanionDrone.pick_target(ship, far, 150.0), -1)
