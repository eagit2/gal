extends Node
## Persistent progress in 3 save slots plus shared settings. `data` is the active slot; every save()
## autosaves into it. Settings live in a separate file shared by all slots (data["settings"] points
## at the same dictionary). On web, user:// is backed by IndexedDB.

const SLOT_COUNT := 3
const SLOT_PATH := "user://slot_%d.json"
const META_PATH := "user://meta.json"
## Pre-slot single save; moved into slot 1 on first launch.
const LEGACY_PATH := "user://save.json"
const SCHEMA_VERSION := 2
const STARTING_SCRAP := 5000

var data: Dictionary = {}
## 0-based index of the slot `data` belongs to.
var active_slot := 0
var settings: Dictionary = default_settings()


func _ready() -> void:
	_migrate_legacy()
	var meta := _read(META_PATH)
	active_slot = clampi(int(meta.get("active_slot", 0)), 0, SLOT_COUNT - 1)
	for key in meta.get("settings", {}):
		settings[key] = meta["settings"][key]
	load_save()


static func default_settings() -> Dictionary:
	return {"music_volume": 0.8, "sfx_volume": 0.8, "muted": false, "auto_fire": false}


static func default_data() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"currency": STARTING_SCRAP,  # hangar scrap
		"high_score": 0,
		"unlocks": [],
		"hangar": {},  # loadout state, see Loadout.default_state
		## Checkpoint of the run in progress (GameState.snapshot), empty when there is none.
		"run": {},
		"last_difficulty": "pilot",
		"saved_at": 0,
	}


static func slot_path(slot: int) -> String:
	return SLOT_PATH % (slot + 1)


## Reloads the active slot from disk (defaults when it is empty).
func load_save() -> void:
	var stored := _read(slot_path(active_slot))
	data = default_data() if stored.is_empty() else migrate(stored)
	data["settings"] = settings


func save() -> void:
	data["saved_at"] = int(Time.get_unix_time_from_system())
	var slot := data.duplicate()
	slot.erase("settings")
	_write(slot_path(active_slot), slot)
	save_settings()


func save_settings() -> void:
	_write(META_PATH, {"active_slot": active_slot, "settings": settings})


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## The stored data of a slot, empty when the slot has never been used.
func slot_info(slot: int) -> Dictionary:
	if slot == active_slot and slot_exists(slot):
		return data
	var stored := _read(slot_path(slot))
	return {} if stored.is_empty() else migrate(stored)


## Makes `slot` the active slot and loads it.
func load_slot(slot: int) -> void:
	active_slot = slot
	load_save()
	save_settings()
	EventBus.save_slot_loaded.emit(slot)


## Starts fresh progress in `slot`, overwriting whatever was there.
func new_game(slot: int, difficulty: StringName) -> void:
	active_slot = slot
	data = default_data()
	data["settings"] = settings
	data["last_difficulty"] = String(difficulty)
	save()
	EventBus.save_slot_loaded.emit(slot)


func has_run() -> bool:
	return not (data["run"] as Dictionary).is_empty()


func save_run(run: Dictionary) -> void:
	data["run"] = run
	save()


func clear_run() -> void:
	data["run"] = {}
	save()


## Fills keys missing from older saves with defaults. Bump SCHEMA_VERSION when the shape changes.
static func migrate(old: Dictionary) -> Dictionary:
	var merged := default_data()
	for key in old:
		merged[key] = old[key]
	merged.erase("settings")
	merged["version"] = SCHEMA_VERSION
	return merged


func _migrate_legacy() -> void:
	if not FileAccess.file_exists(LEGACY_PATH) or slot_exists(0):
		return
	var old := _read(LEGACY_PATH)
	if old.has("settings"):
		_write(META_PATH, {"active_slot": 0, "settings": old["settings"]})
	_write(slot_path(0), migrate(old))
	DirAccess.remove_absolute(LEGACY_PATH)


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _write(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(value))
