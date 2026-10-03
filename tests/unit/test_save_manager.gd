extends TestCase

const SaveManagerScript := preload("res://autoload/save_manager.gd")


func test_default_data_has_schema_version() -> void:
	expect_eq(SaveManagerScript.default_data()["version"], SaveManagerScript.SCHEMA_VERSION)


func test_migrate_fills_missing_keys_and_keeps_existing() -> void:
	var migrated := SaveManagerScript.migrate({"version": 0, "currency": 42})
	expect_eq(migrated["currency"], 42, "currency")
	expect_true(migrated.has("hangar"), "hangar added")
	expect_true(not migrated.has("settings"), "settings live outside slots")
	expect_eq(migrated["version"], SaveManagerScript.SCHEMA_VERSION, "version bumped")


func test_default_data_has_no_saved_run() -> void:
	var data := SaveManagerScript.default_data()
	expect_eq(data["run"], {}, "run")
	expect_eq(data["last_difficulty"], "pilot", "last difficulty")


func test_new_slot_starts_with_scrap() -> void:
	expect_eq(SaveManagerScript.default_data()["currency"], SaveManagerScript.STARTING_SCRAP)


func test_slots_have_separate_files() -> void:
	expect_true(SaveManagerScript.slot_path(0) != SaveManagerScript.slot_path(2), "paths differ")
