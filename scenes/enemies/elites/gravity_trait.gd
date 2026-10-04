class_name GravityTrait
extends EliteTrait
## Its core drags the player sideways toward it and is shielded, except for `open_time` after
## each pulse (a ring of shots). Counter: fight the pull, and hit the core right after a pulse.

@export var well_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/gravity_well.tscn")
@export var pull := 95.0
@export var closed_time := 4.5
@export var open_time := 2.2
@export var pulse_shots := 12
@export var pulse_speed := 150.0


func begin(elite: Elite) -> void:
	state(elite)["open"] = false
	state(elite)["t"] = 0.0
	var well: Node2D = well_visual.instantiate()
	elite.add_child(well)
	state(elite)["well"] = well


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var t: float = state(elite)["t"] + delta
	var open: bool = state(elite)["open"]
	if not open and is_instance_valid(elite.target) and elite.target.alive:
		var dx := elite.global_position.x - elite.target.global_position.x
		elite.target.position.x += signf(dx) * minf(absf(dx), pull * delta)
	if not open and t >= closed_time:
		for i in pulse_shots:
			elite.fire(Vector2.from_angle(TAU * i / pulse_shots), pulse_speed)
		open = true
		t = 0.0
	elif open and t >= open_time:
		open = false
		t = 0.0
	state(elite)["open"] = open
	state(elite)["t"] = t
	(state(elite)["well"] as Node).call("set_open", open)


func absorb(elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	return amount if state(elite)["open"] else 0
