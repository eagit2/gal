class_name TimeStopTrait
extends EliteTrait
## Warns, then freezes your ship for a moment while its shots keep flying. Counter: be in a safe
## spot when the warning ends.

@export var warn_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/time_warn.tscn")
@export var interval := 9.0
@export var warn_time := 1.2
@export var freeze_time := 1.0


func begin(elite: Elite) -> void:
	state(elite)["t"] = 0.0
	state(elite)["warn"] = 0.0
	state(elite)["after"] = 0.0
	var warn: Node2D = warn_visual.instantiate()
	warn.visible = false
	elite.add_child(warn)
	state(elite)["visual"] = warn


func tick(elite: Elite, delta: float) -> void:
	var s := state(elite)
	var player := elite.target
	var visual: Node2D = s["visual"]
	if not elite.entered or not is_instance_valid(player) or not player.alive or GameState.freeze_left > 0.0:
		s["warn"] = 0.0
		visual.visible = false
		return
	if s["after"] > 0.0:
		s["after"] -= delta
		if s["after"] <= 0.0:
			elite.fire_fan()  # Aimed at the frozen ship: the reason not to stand in line.
	if s["warn"] > 0.0:
		s["warn"] -= delta
		visual.call("set_warning", clampf(1.0 - s["warn"] / warn_time, 0.0, 1.0), player.global_position)
		if s["warn"] <= 0.0:
			visual.visible = false
			player.freeze_for(freeze_time)
			s["after"] = freeze_time * 0.4
		return
	s["t"] += delta
	if s["t"] >= interval:
		s["t"] = 0.0
		s["warn"] = warn_time
		visual.visible = true


func end(elite: Elite) -> void:
	var visual: Variant = state(elite).get("visual")
	if is_instance_valid(visual):
		(visual as Node2D).visible = false
