class_name PhaseTrait
extends EliteTrait
## Phases out (see-through, shots pass through), slides over the player, then snaps back solid and
## fires at once. Counter: it can only be hit while solid; the shimmer warns it is about to return.

@export var solid_time := 1.8
@export var phase_time := 2.0
@export var chase_speed := 240.0
@export var phased_alpha := 0.15


func begin(elite: Elite) -> void:
	elite.state["phased"] = false
	elite.state["t"] = 0.0


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var t: float = elite.state["t"] + delta
	if elite.state["phased"]:
		if is_instance_valid(elite.target):
			elite.position.x = move_toward(elite.position.x, clampf(elite.target.global_position.x, Elite.MIN_X, Elite.MAX_X), chase_speed * delta)
		var shimmer := 0.5 * absf(sin(t * 25.0)) if t > phase_time - 0.5 else 0.0
		elite.modulate.a = phased_alpha + shimmer
		if t >= phase_time:
			_set_phased(elite, false)
			elite.fire_fan()
			t = 0.0
	elif t >= solid_time:
		_set_phased(elite, true)
		t = 0.0
	elite.state["t"] = t


func end(elite: Elite) -> void:
	_set_phased(elite, false)


func _set_phased(elite: Elite, on: bool) -> void:
	elite.state["phased"] = on
	elite.hurtbox.invulnerable = on
	elite.can_fire = not on
	elite.modulate.a = phased_alpha if on else 1.0
