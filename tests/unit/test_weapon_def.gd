extends TestCase


func test_single_shot_goes_straight() -> void:
	var weapon := WeaponDef.new()
	expect_eq(weapon.shot_angles(), [0.0] as Array[float])


func test_spread_is_even_and_symmetric() -> void:
	var weapon := WeaponDef.new()
	weapon.spread_count = 3
	weapon.spread_angle = 30.0
	expect_eq(weapon.shot_angles(), [-15.0, 0.0, 15.0] as Array[float])
