class_name CaptureBrain
extends EnemyBrain
## Classic tractor beam: dives to a spot above the player, stops, and projects a beam downward. A
## player under the beam is captured (EventBus.player_captured). Shooting the captor while it dives
## later frees the ship as a wingman (CaptureSystem).

@export var hover_y := 470.0
@export var beam_time := 3.0
## Beam half-width at the captor and how much it widens per pixel downward.
@export var beam_half_width := 26.0
@export var beam_spread := 0.32
@export var beam_scene: PackedScene


func begin(enemy: Enemy) -> void:
	super(enemy)
	enemy.velocity = Vector2(0, speed * 0.3)
	# Pick the spot once: the player has a moment to read the dive and move away.
	enemy.escort_offset = Vector2(enemy.predicted_player(0.3).x, hover_y)


func tick(enemy: Enemy, delta: float) -> bool:
	match enemy.phase:
		0:
			var goal := enemy.escort_offset
			enemy.steer(goal - enemy.position, speed, turn_rate, delta)
			if enemy.position.distance_to(goal) < 24.0 or enemy.phase_time > 3.5:
				enemy.velocity = Vector2.ZERO
				var beam: Node2D = beam_scene.instantiate()
				beam.name = "TractorBeam"
				enemy.add_child(beam)
				beam.rotation = -enemy.rotation
				enemy.set_phase(1)
		1:
			enemy.velocity = Vector2.ZERO
			var beam := enemy.get_node_or_null("TractorBeam") as Node2D
			if beam:
				beam.rotation = -enemy.rotation
			if _in_beam(enemy):
				_drop_beam(enemy)
				EventBus.player_captured.emit(enemy)
				return true
			if enemy.phase_time > beam_time:
				_drop_beam(enemy)
				return true
	return false


func _in_beam(enemy: Enemy) -> bool:
	if not is_instance_valid(enemy.target) or not enemy.target.alive or enemy.target.dual:
		return false
	var offset := enemy.target.global_position - enemy.global_position
	return offset.y > 0.0 and absf(offset.x) < beam_half_width + offset.y * beam_spread and enemy.phase_time > 0.5


func _drop_beam(enemy: Enemy) -> void:
	var beam := enemy.get_node_or_null("TractorBeam")
	if beam:
		beam.queue_free()
