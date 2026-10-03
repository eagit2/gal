extends TestCase
## Capture data and the hangar's freeze and scrap parts.


func test_capture_brain_has_a_beam() -> void:
	var brain: CaptureBrain = load("res://data/brains/capture.tres")
	expect_true(brain.beam_scene != null, "beam visual")
	expect_true(brain.beam_time > 0.0, "beam time")


func test_some_enemy_can_capture() -> void:
	var warden: EnemyDef = load("res://data/enemies/warden.tres")
	expect_true(warden.can_capture, "warden captures")


func test_hangar_sells_freeze_and_scrap_parts() -> void:
	expect_true(Hangar.CATALOG.part(&"cryo_pulse") != null and Hangar.CATALOG.part(&"scrap_compactor") != null, "parts in catalog")
