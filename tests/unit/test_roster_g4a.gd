extends TestCase
## Aegis dome arc, weakness damage, Copy Robot numbers, and that the G4a rows carry their traits.


func test_open_arc() -> void:
	expect_true(ReflectShieldTrait.in_open_arc(0.1, 0.0, 60), "inside the gap")
	expect_true(not ReflectShieldTrait.in_open_arc(1.0, 0.0, 60), "outside the gap")
	expect_true(ReflectShieldTrait.in_open_arc(-PI + 0.1, PI - 0.1, 60), "gap across the wrap")


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
	expect_true(Roster.elite(&"flash").traits_for_phase(0).any(func(t: EliteTrait) -> bool: return t is TimeStopTrait), "flash")
	var weak: Array = Roster.elite(&"aegis").traits_for_phase(0).filter(func(t: EliteTrait) -> bool: return t is WeaknessTrait)
	expect_true(weak.size() == 1 and weak[0].weapon == "rail", "aegis weak to rail")
	expect_true(Roster.elite(&"matriarch").traits_for_phase(1).any(func(t: EliteTrait) -> bool: return t is ReflectShieldTrait and t.arc_open == 90), "matriarch phase 2 dome")
