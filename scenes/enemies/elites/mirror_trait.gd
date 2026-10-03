class_name MirrorTrait
extends EliteTrait
## Raises a mirror that bounces the player's shots back at them. It glows before it rises and
## drops after `up_time`. Counter: hold fire while the mirror is up; hit it while it's down.

enum Phase { DOWN, WARN, UP }

@export var mirror_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/mirror.tscn")
@export var down_time := 2.4
@export var warn_time := 0.6
@export var up_time := 2.6
@export var reflect_speed := 340.0
## At most one reflected shot per this many seconds.
@export var reflect_gap := 0.12


func begin(elite: Elite) -> void:
	state(elite)["phase"] = Phase.DOWN
	state(elite)["t"] = 0.0
	state(elite)["reflect"] = 0.0
	var mirror: Node2D = mirror_visual.instantiate()
	elite.add_child(mirror)
	state(elite)["mirror"] = mirror


func tick(elite: Elite, delta: float) -> void:
	var t: float = state(elite)["t"] + delta
	state(elite)["reflect"] -= delta
	var phase: Phase = state(elite)["phase"]
	var limit: float = [down_time, warn_time, up_time][phase]
	if t >= limit:
		t = 0.0
		phase = ((phase + 1) % 3) as Phase
		state(elite)["phase"] = phase
	state(elite)["t"] = t
	(state(elite)["mirror"] as Node).call("set_phase", phase)


func absorb(elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	if state(elite)["phase"] != Phase.UP:
		return amount
	if state(elite)["reflect"] <= 0.0 and is_instance_valid(elite.target):
		state(elite)["reflect"] = reflect_gap
		# Deferred: hits land inside a physics callback, where shots can't be added.
		elite.fire.call_deferred(elite.global_position.direction_to(elite.target.global_position), reflect_speed)
	return 0
