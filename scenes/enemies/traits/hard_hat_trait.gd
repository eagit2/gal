class_name HardHatTrait
extends EnemyTrait
## Hides under a helmet that no shot can hurt, then peeks out to fire a spread. Counter: hit it
## while it peeks.

@export var hide_time := 1.8
@export var peek_time := 0.9
@export var spread_shots := 3
@export var spread_angle := 30.0

## Share of the peek that passes before the volley, so you get a window to shoot first.
const FIRE_AT := 0.45


## Fan offsets in degrees: `count` shots `angle` degrees apart, centered on the aim.
static func spread_offsets(count: int, angle: float) -> Array[float]:
	var offsets: Array[float] = []
	for i in count:
		offsets.append((i - (count - 1) / 2.0) * angle)
	return offsets


func begin(enemy: Enemy) -> void:
	var s := state(enemy)
	s["t"] = randf() * hide_time  # Out of step, so a squad doesn't peek together.
	s["hiding"] = true
	s["fired"] = false
	enemy.set_shielded(true)


func tick(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	var t: float = s["t"] + delta
	enemy.fire_cooldown = 9.0  # The brain stays quiet; the volley is ours.
	if s["hiding"]:
		if t >= hide_time:
			t = 0.0
			s["hiding"] = false
			s["fired"] = false
			enemy.set_shielded(false)
	else:
		if not s["fired"] and t >= peek_time * FIRE_AT:
			s["fired"] = true
			_volley(enemy)
		if t >= peek_time:
			t = 0.0
			s["hiding"] = true
			enemy.set_shielded(true)
	s["t"] = t


func _volley(enemy: Enemy) -> void:
	if enemy.state != Enemy.State.DIVING or not is_instance_valid(enemy.target):
		return
	var aim := enemy.predicted_player(0.2)
	for offset in spread_offsets(spread_shots, spread_angle):
		enemy.fire_at(aim, 0.0, offset)
