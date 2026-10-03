extends TestCase
## Fire rate upgrades: small steps, then a big jump at max level.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _rate(level: int) -> float:
	var def := CATALOG.part(&"pulse_laser")
	var state := Loadout.default_state(CATALOG)
	state["parts"]["pulse_laser"] = {"speed": level}
	var stats := UpgradeSystem.compute(def.effects_at(state["parts"]["pulse_laser"]))
	return float(stats[&"fire_rate"])


func test_last_level_is_the_big_jump() -> void:
	var step := _rate(4) - _rate(3)
	var last := _rate(5) - _rate(4)
	expect_true(last > step * 5.0, "last step %.2f vs %.2f" % [last, step])
	expect_true(absf(_rate(5) - 2.5) < 0.001, "max multiplier 2.5")
