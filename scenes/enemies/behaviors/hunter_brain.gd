class_name HunterBrain
extends EnemyBrain
## Squad leader: pulls nearby formation enemies along as escorts, then makes sweeping passes that
## cut off where the player is heading, firing spreads. Once damaged it stops shooting and rams.

@export var escorts := 2
@export var escort_radius := 110.0
@export var lead := 0.6
@export var passes := 2
@export var spread_shots := 3
@export var spread_degrees := 14.0


func begin(enemy: Enemy) -> void:
	super(enemy)
	enemy.velocity = Vector2(0, -speed * 0.5)
	enemy.shots_left = passes
	var offsets: Array[Vector2] = [Vector2(-38, -30), Vector2(38, -30), Vector2(0, -60)]
	var i := 0
	for escort in enemy.nearby_idle(escort_radius, escorts):
		escort.start_escort(enemy, offsets[i % offsets.size()])
		i += 1


func tick(enemy: Enemy, delta: float) -> bool:
	var aim := enemy.predicted_player(lead)
	if enemy.is_damaged():
		enemy.steer(enemy.predicted_player(0.2) - enemy.position, speed * 1.5, turn_rate * 1.5, delta)
		return false
	match enemy.phase:
		0:
			var goal := Vector2(aim.x, aim.y - 150.0)
			enemy.steer(goal - enemy.position, speed, turn_rate, delta)
			if enemy.fire_cooldown <= 0.0 and absf(enemy.position.x - aim.x) < 70.0 and enemy.position.y < aim.y - 220.0:
				for i in spread_shots:
					enemy.fire_at(aim, 0.0, (i - (spread_shots - 1) / 2.0) * spread_degrees)
				enemy.fire_cooldown = fire_interval
			if enemy.position.y > aim.y - 200.0 or enemy.phase_time > 3.0:
				enemy.set_phase(1)
		1:
			# Swing out and climb for the next pass.
			var side := 1.0 if enemy.position.x < 270.0 else -1.0
			enemy.steer(Vector2(side, -1.2), speed * 1.1, turn_rate, delta)
			if enemy.phase_time > 1.1:
				enemy.shots_left -= 1
				if enemy.shots_left <= 0:
					return true
				enemy.set_phase(0)
	return false
