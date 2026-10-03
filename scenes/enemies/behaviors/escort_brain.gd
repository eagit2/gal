class_name EscortBrain
extends EnemyBrain
## Holds a slot beside its squad leader and fires when lined up. If the leader dies or goes home,
## the escort switches to its own brain and keeps attacking.


func tick(enemy: Enemy, delta: float) -> bool:
	var leader := enemy.leader
	if not is_instance_valid(leader) or leader.state != Enemy.State.DIVING:
		enemy.release_escort()
		return false
	var heading := leader.velocity.angle() - PI / 2.0 if leader.velocity.length_squared() > 1.0 else 0.0
	var goal := leader.position + enemy.escort_offset.rotated(heading)
	var to_goal := goal - enemy.position
	enemy.steer(to_goal, minf(leader.velocity.length() * 1.2 + to_goal.length() * 2.0, speed * 1.6), turn_rate * 3.0, delta)
	var aim := enemy.predicted_player(0.3)
	if enemy.fire_cooldown <= 0.0 and absf(enemy.position.x - aim.x) < 50.0 and enemy.position.y < aim.y - 220.0:
		enemy.fire_at(aim)
		enemy.fire_cooldown = fire_interval
	return false
