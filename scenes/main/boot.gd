extends Node
## First scene. Applies saved settings, then shows the title.


func _ready() -> void:
	var settings: Dictionary = SaveManager.data["settings"]
	AudioManager.set_bus_volume("Music", settings["music_volume"])
	AudioManager.set_bus_volume("SFX", settings["sfx_volume"])
	SceneRouter.go_to("res://scenes/main/title.tscn")
