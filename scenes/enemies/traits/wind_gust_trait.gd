class_name WindGustTrait
extends EnemyTrait
## Blows gusts that shove your ship sideways while bullets fly through. Counter: lean into the
## wind, and kill it to stop the gusts.

const STREAKS := preload("res://assets/art/dusk_armada/enemies/gust_streaks.gd")
## Seconds of warning (faint wind lines) before a gust starts.
const WARN := 0.7

@export var interval := 4.0
@export var gust_time := 1.5
@export var push := 160.0


## The player's x after `delta` seconds of wind blowing `direction` (+1 right, -1 left).
static func pushed_x(x: float, direction: float, speed: float, delta: float, min_x: float, max_x: float) -> float:
	return clampf(x + direction * speed * delta, min_x, max_x)


func begin(enemy: Enemy) -> void:
	var s := state(enemy)
	s["t"] = interval * 0.5
	s["phase"] = 0  # 0 calm, 1 warning, 2 blowing
	s["dir"] = 1.0


func tick(enemy: Enemy, delta: float) -> void:
	if enemy.state == Enemy.State.ENTERING:
		return
	var s := state(enemy)
	var t: float = s["t"] - delta
	var phase: int = s["phase"]
	var streaks := s.get("streaks") as Node2D
	if phase == 2:
		_blow(enemy, s["dir"], delta)
	if t <= 0.0:
		match phase:
			0:
				phase = 1
				t = WARN
				s["dir"] = _pick_direction(enemy)
				streaks = _make_streaks(enemy, s["dir"])
				s["streaks"] = streaks
			1:
				phase = 2
				t = gust_time
				streaks.set("strength", 0.7)
			_:
				phase = 0
				t = maxf(0.5, interval - WARN - gust_time)
				_drop_streaks(s)
	s["phase"] = phase
	s["t"] = t


func killed(enemy: Enemy) -> void:
	_drop_streaks(state(enemy))


## Blows toward the nearer side wall half the time, so a gust threatens an edge squeeze.
func _pick_direction(enemy: Enemy) -> float:
	var player := enemy.target
	if is_instance_valid(player) and randf() < 0.5:
		return 1.0 if player.global_position.x > 270.0 else -1.0
	return 1.0 if randf() < 0.5 else -1.0


func _blow(enemy: Enemy, direction: float, delta: float) -> void:
	var player := enemy.target
	if not is_instance_valid(player) or not player.alive or player.frozen_left > 0.0:
		return
	var max_x := 540.0 - Player.MARGIN - (Player.WINGMAN_OFFSET.x if player.dual else 0.0)
	player.position.x = pushed_x(player.position.x, direction, push, delta, Player.MARGIN, max_x)


func _make_streaks(enemy: Enemy, direction: float) -> Node2D:
	var streaks: Node2D = Node2D.new()
	streaks.set_script(STREAKS)
	streaks.set("direction", direction)
	streaks.set("strength", 0.25)
	streaks.z_index = 50
	var parent: Node = enemy.entities if is_instance_valid(enemy.entities) else enemy.get_parent()
	parent.add_child(streaks)
	return streaks


func _drop_streaks(s: Dictionary) -> void:
	var streaks := s.get("streaks") as Node
	if is_instance_valid(streaks):
		streaks.queue_free()
	s.erase("streaks")
