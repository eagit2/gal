class_name MirrorTrait
extends EliteTrait
## Raises a mirror that bounces the player's shots back at them. It glows before it rises and
## drops after `up_time`. Counter: hold fire while the mirror is up; hit it while it's down.

enum Phase { DOWN, WARN, UP }

@export var mirror_visual: PackedScene
@export var down_time := 2.4
@export var warn_time := 0.6
@export var up_time := 2.6
@export var reflect_speed := 340.0
## At most one reflected shot per this many seconds.
@export var reflect_gap := 0.12


func begin(elite: Elite) -> void:
	elite.state["phase"] = Phase.DOWN
	elite.state["t"] = 0.0
	elite.state["reflect"] = 0.0
	var mirror: Node2D = mirror_visual.instantiate()
	elite.add_child(mirror)
	elite.state["mirror"] = mirror


func tick(elite: Elite, delta: float) -> void:
	var t: float = elite.state["t"] + delta
	elite.state["reflect"] -= delta
	var phase: Phase = elite.state["phase"]
	var limit: float = [down_time, warn_time, up_time][phase]
	if t >= limit:
		t = 0.0
		phase = ((phase + 1) % 3) as Phase
		elite.state["phase"] = phase
	elite.state["t"] = t
	(elite.state["mirror"] as Node).call("set_phase", phase)


func absorb(elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	if elite.state["phase"] != Phase.UP:
		return amount
	if elite.state["reflect"] <= 0.0 and is_instance_valid(elite.target):
		elite.state["reflect"] = reflect_gap
		# Deferred: hits land inside a physics callback, where shots can't be added.
		elite.fire.call_deferred(elite.global_position.direction_to(elite.target.global_position), reflect_speed)
	return 0
