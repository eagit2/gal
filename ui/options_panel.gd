class_name OptionsPanel
extends MenuPanel
## Music and SFX volume plus mute. Settings are shared by every save slot.


func _ready() -> void:
	add_label("OPTIONS", 20)
	_add_slider("MUSIC", "music_volume", "Music")
	_add_slider("SFX", "sfx_volume", "SFX")
	var mute := CheckButton.new()
	mute.text = "MUTE"
	mute.button_pressed = SaveManager.settings["muted"]
	mute.toggled.connect(_on_mute)
	box.add_child(mute)
	add_button("BACK", _on_cancel)
	focus_first()


func _add_slider(text: String, key: String, bus: String) -> void:
	add_label(text, 14)
	var slider := HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.1
	slider.value = SaveManager.settings[key]
	slider.custom_minimum_size.y = 32
	slider.value_changed.connect(func(value: float) -> void:
		SaveManager.settings[key] = value
		AudioManager.set_bus_volume(bus, value)
		SaveManager.save_settings())
	box.add_child(slider)


func _on_mute(muted: bool) -> void:
	SaveManager.settings["muted"] = muted
	AudioManager.set_muted(muted)
	SaveManager.save_settings()
