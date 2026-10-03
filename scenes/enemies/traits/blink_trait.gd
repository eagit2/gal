class_name BlinkTrait
extends EnemyTrait
## Mid-dive it flickers, then teleports sideways. Counter: shoot it while it flickers, or aim where
## it lands (always `distance` to one side, toward the middle near the edges).

@export var interval := 1.4
@export var telegraph := 0.4
@export var distance := 120.0


func tick(enemy: Enemy, delta: float) -> void:
	if enemy.state != Enemy.State.DIVING:
		state(enemy)["t"] = 0.0
		enemy.modulate.a = 1.0
		return
	var t: float = state(enemy).get("t", 0.0) + delta
	if t >= interval:
		var side := 1.0 if enemy.position.x < 270.0 else -1.0
		if randf() < 0.35:
			side = -side
		enemy.position.x = clampf(enemy.position.x + side * distance, Enemy.MIN_X, Enemy.MAX_X)
		enemy.modulate.a = 1.0
		t = 0.0
	elif t >= interval - telegraph:
		enemy.modulate.a = 0.25 + 0.75 * absf(sin(t * 30.0))
	state(enemy)["t"] = t
