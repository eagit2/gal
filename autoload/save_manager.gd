extends Node
## Persistent meta progress and settings. On web, user:// is backed by IndexedDB.

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 1

var data: Dictionary = {}


func _ready() -> void:
	load_save()


static func default_data() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"currency": 0,
		"high_score": 0,
		"unlocks": [],
		"settings": {"music_volume": 0.8, "sfx_volume": 0.8, "auto_fire": false},
	}


func load_save() -> void:
	data = default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		data = migrate(parsed)


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


## Fills keys missing from older saves with defaults. Bump SCHEMA_VERSION when the shape changes.
static func migrate(old: Dictionary) -> Dictionary:
	var merged := default_data()
	for key in old:
		merged[key] = old[key]
	merged["version"] = SCHEMA_VERSION
	return merged
