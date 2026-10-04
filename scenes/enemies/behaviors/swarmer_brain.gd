class_name SwarmerBrain
extends EnemyBrain
## Kamikaze: peels out of formation, then homes on where the player is heading and speeds up.
## Once level with the player it stops turning and shoots past; bold ones come back around.

@export var peel_time := 0.35
@export var top_speed := 470.0
## Seconds of player movement to lead the aim by.
@export var lead := 0.35
@export var shots := 1
@export var reattack_chance := 0.45


func begin(enemy: Enemy) -> void:
	super(enemy)
	var side := -1.0 if enemy.position.x < 270.0 else 1.0
	enemy.velocity = Vector2(side * 0.7, -1.0).normalized() * speed * enemy.kamikaze_speed * 0.6
	enemy.shots_left = shots


func tick(enemy: Enemy, delta: float) -> bool:
	if enemy.phase == 0:
		enemy.steer(Vector2.DOWN, speed * enemy.kamikaze_speed * 0.8, turn_rate * 1.5, delta)
		if enemy.phase_time >= peel_time:
			enemy.set_phase(1)
		return false
	var cruise := lerpf(speed, top_speed, minf(1.0, enemy.phase_time / 1.5)) * enemy.kamikaze_speed
	var aim := enemy.predicted_player(lead)
	if enemy.position.y < aim.y - 40.0:
		enemy.steer(aim - enemy.position, cruise, turn_rate, delta)
	else:
		enemy.steer(enemy.velocity, cruise, 0.0, delta)
	if enemy.shots_left > 0 and enemy.fire_cooldown <= 0.0 and enemy.position.y > 220.0 and enemy.position.y < aim.y - 200.0:
		enemy.fire_at(aim)
		enemy.shots_left -= 1
		enemy.fire_cooldown = fire_interval
	return false


func continue_after_wrap(enemy: Enemy) -> bool:
	if randf() >= reattack_chance * enemy.aggression:
		return false
	enemy.set_phase(1)
	enemy.velocity = Vector2.DOWN * speed * enemy.kamikaze_speed
	enemy.shots_left = shots
	return true
