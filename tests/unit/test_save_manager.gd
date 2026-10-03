extends TestCase

const SaveManagerScript := preload("res://autoload/save_manager.gd")


func test_default_data_has_schema_version() -> void:
	expect_eq(SaveManagerScript.default_data()["version"], SaveManagerScript.SCHEMA_VERSION)


func test_migrate_fills_missing_keys_and_keeps_existing() -> void:
	var migrated := SaveManagerScript.migrate({"version": 0, "currency": 42})
	expect_eq(migrated["currency"], 42, "currency")
	expect_true(migrated.has("settings"), "settings added")
	expect_eq(migrated["version"], SaveManagerScript.SCHEMA_VERSION, "version bumped")


func test_default_data_has_no_saved_run() -> void:
	var data := SaveManagerScript.default_data()
	expect_eq(data["run"], {}, "run")
	expect_eq(data["last_difficulty"], "pilot", "last difficulty")
