extends Control
## Title screen. The first input also unlocks browser audio.

@onready var _prompt: Label = $Prompt


func _ready() -> void:
	$HighScore.text = "HIGH SCORE  %d" % SaveManager.data["high_score"]
	var tween := create_tween().set_loops()
	tween.tween_property(_prompt, "modulate:a", 0.2, 0.6)
	tween.tween_property(_prompt, "modulate:a", 1.0, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_prompt.text = "STARTING..."  # Difficulty select arrives in M4; game scene in M1.
