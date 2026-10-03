class_name SweepTrait
extends EliteTrait
## Every `interval` it stops, shows a thin aiming line, then sweeps a long laser across the screen
## below it. The beam costs a life on contact. Counter: watch the aiming line and get behind the
## sweep (it only goes one way), or freeze it.

@export var beam_scene: PackedScene = preload("res://scenes/enemies/elites/sweep_beam.tscn")
@export var interval := 6.5
@export var aim_time := 1.1
@export var sweep_time := 1.6
## Half the sweep arc, radians from straight down.
@export var arc := 1.0


func begin(elite: Elite) -> void:
	state(elite)["t"] = 0.0
	state(elite)["phase"] = 0
	var beam: Node2D = beam_scene.instantiate()
	elite.add_child(beam)
	state(elite)["beam"] = beam


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var t: float = state(elite)["t"] + delta
	var beam: Node2D = state(elite)["beam"]
	var side: float = state(elite).get("side", 1.0)
	match state(elite)["phase"]:
		0:
			if t >= interval:
				# Start on the player's side and sweep away across them.
				side = 1.0 if is_instance_valid(elite.target) and elite.target.global_position.x > elite.global_position.x else -1.0
				state(elite)["side"] = side
				_next(elite, 1)
				t = 0.0
		1:
			beam.rotation = side * arc
			beam.call("set_mode", 1)
			elite.can_fire = false
			if t >= aim_time:
				_next(elite, 2)
				t = 0.0
		2:
			beam.rotation = side * lerpf(arc, -arc, t / sweep_time)
			beam.call("set_mode", 2)
			if t >= sweep_time:
				beam.call("set_mode", 0)
				elite.can_fire = true
				_next(elite, 0)
				t = 0.0
	state(elite)["t"] = t


func end(elite: Elite) -> void:
	elite.can_fire = true


func _next(elite: Elite, phase: int) -> void:
	state(elite)["phase"] = phase
