class_name DashTrait
extends EnemyTrait
## Mid-dive it flashes, snaps sideways toward the player at high speed, then fires. Counter: the
## flash warns you, and it pauses after the dash.

@export var interval := 1.5
@export var telegraph := 0.3
@export var dash_time := 0.18
@export var dash_speed := 950.0

const FLASH := Color(1.8, 1.8, 1.8)


func tick(enemy: Enemy, delta: float) -> void:
	if enemy.state != Enemy.State.DIVING:
		enemy.trait_state["t"] = 0.0
		enemy.modulate = Color.WHITE
		return
	var t: float = enemy.trait_state.get("t", 0.0) + delta
	if t < interval - telegraph:
		enemy.trait_state["t"] = t
		return
	if t < interval:
		enemy.modulate = FLASH
		enemy.trait_state["dir"] = signf(enemy.predicted_player(0.2).x - enemy.position.x)
	elif t < interval + dash_time:
		enemy.modulate = Color.WHITE
		enemy.position.x = clampf(enemy.position.x + enemy.trait_state.get("dir", 1.0) * dash_speed * delta, Enemy.MIN_X, Enemy.MAX_X)
	else:
		enemy.fire_at(enemy.predicted_player(0.3))
		t = 0.0
	enemy.trait_state["t"] = t
