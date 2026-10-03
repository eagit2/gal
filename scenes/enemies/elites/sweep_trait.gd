class_name SweepTrait
extends EliteTrait
## Every `interval` it stops, shows a thin aiming line, then sweeps a long laser across the screen
## below it. The beam costs a life on contact. Counter: watch the aiming line and get behind the
## sweep (it only goes one way), or freeze it.

@export var beam_scene: PackedScene
@export var interval := 6.5
@export var aim_time := 1.1
@export var sweep_time := 1.6
## Half the sweep arc, radians from straight down.
@export var arc := 1.0


func begin(elite: Elite) -> void:
	elite.state["t"] = 0.0
	elite.state["phase"] = 0
	var beam: Node2D = beam_scene.instantiate()
	elite.add_child(beam)
	elite.state["beam"] = beam


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var t: float = elite.state["t"] + delta
	var beam: Node2D = elite.state["beam"]
	var side: float = elite.state.get("side", 1.0)
	match elite.state["phase"]:
		0:
			if t >= interval:
				# Start on the player's side and sweep away across them.
				side = 1.0 if is_instance_valid(elite.target) and elite.target.global_position.x > elite.global_position.x else -1.0
				elite.state["side"] = side
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
	elite.state["t"] = t


func _next(elite: Elite, phase: int) -> void:
	elite.state["phase"] = phase
