extends TestCase
## Aegis dome cycle, weakness damage, Copy Robot numbers, and that the G4a rows carry their traits.


func test_shield_cycle() -> void:
	expect_eq(ReflectShieldTrait.step(5.0, 0.0, 1.0, 5.0, 2.0), Vector2(4.0, 0.0), "counting down while up")
	expect_eq(ReflectShieldTrait.step(0.5, 0.0, 1.0, 5.0, 2.0), Vector2(0.0, 2.0), "overloads")
	expect_eq(ReflectShieldTrait.step(0.0, 2.0, 1.0, 5.0, 2.0), Vector2(0.0, 1.0), "down")
	expect_eq(ReflectShieldTrait.step(0.0, 0.5, 1.0, 5.0, 2.0), Vector2(5.0, 0.0), "reboots")


func test_weakness_boost() -> void:
	expect_eq(WeaknessTrait.boosted(1, 3), 3, "x3")
	expect_eq(WeaknessTrait.boosted(1, 1), 2, "at least +1")
	expect_eq(WeaknessTrait.boosted(0, 3), 0, "blocked stays blocked")


func test_copy_numbers() -> void:
	expect_eq(CopyWeaponTrait.copy_damage(1, 0.7), 1, "min 1")
	expect_eq(CopyWeaponTrait.copy_damage(10, 0.7), 7, "scaled")
	expect_true(CopyWeaponTrait.copy_speed(900.0) <= 380.0 and CopyWeaponTrait.copy_speed(100.0) >= 180.0, "clamped")


func test_rows_carry_traits() -> void:
	expect_true(Roster.elite(&"aegis").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is ReflectShieldTrait), "aegis")
	expect_true(Roster.elite(&"copy_robot").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is CopyWeaponTrait), "copy robot")
	var weak: Array = Roster.elite(&"aegis").traits_for_phase(0).filter(func(t: EliteTrait) -> bool: return t is WeaknessTrait)
	expect_true(weak.size() == 1 and weak[0].weapon == "rail", "aegis weak to rail")
	expect_true(Roster.elite(&"matriarch").traits_for_phase(1).any(func(t: EliteTrait) -> bool: return t is ReflectShieldTrait), "matriarch phase 2 dome")
