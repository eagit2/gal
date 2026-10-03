class_name StraferBrain
extends EnemyBrain
## Gunship: drops to a firing line above the player, shadows the player sideways while firing
## bursts, then pulls back to formation. Sometimes it commits and dives straight at the player.

## Firing line height above the player, plus up to `line_jitter` more per enemy.
@export var line_offset := 260.0
@export var line_jitter := 120.0
@export var strafe_time := 3.0
@export var burst := 3
@export var burst_gap := 0.14
@export var track_speed := 230.0
@export var commit_chance := 0.3


func begin(enemy: Enemy) -> void:
	super(enemy)
	enemy.velocity = Vector2(0, -speed * 0.4)
	enemy.shots_left = burst
	enemy.aim_facing = true


func tick(enemy: Enemy, delta: float) -> bool:
	var player := enemy.predicted_player(0.25)
	var line_y := clampf(player.y - line_offset - enemy.quirk * line_jitter, 170.0, 660.0)
	match enemy.phase:
		0:
			var goal := Vector2(lerpf(enemy.position.x, player.x, 0.6), line_y)
			enemy.steer(goal - enemy.position, speed, turn_rate, delta)
			if enemy.position.distance_to(goal) < 40.0 or enemy.phase_time > 2.0:
				enemy.set_phase(1)
		1:
			var weave := sin(enemy.phase_time * 3.0 + enemy.quirk * TAU) * 70.0
			var want := Vector2(clampf((player.x + weave - enemy.position.x) * 3.0, -track_speed, track_speed), (line_y - enemy.position.y) * 2.0)
			enemy.velocity = enemy.velocity.move_toward(want, 900.0 * delta)
			if enemy.fire_cooldown <= 0.0:
				enemy.fire_at(player, 6.0)
				enemy.shots_left -= 1
				enemy.fire_cooldown = burst_gap
				if enemy.shots_left <= 0:
					enemy.shots_left = burst
					enemy.fire_cooldown = fire_interval
			if enemy.phase_time > strafe_time:
				if randf() >= commit_chance * enemy.aggression:
					return true
				enemy.aim_facing = false
				enemy.set_phase(2)
		2:
			enemy.steer(enemy.predicted_player(0.3) - enemy.position, speed * 1.5, turn_rate, delta)
	return false
