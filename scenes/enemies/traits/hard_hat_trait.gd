class_name HardHatTrait
extends EnemyTrait
## Slowly creeps toward the player. While it watches, any shot it sees coming makes it duck under
## a helmet no shot can hurt; it pops back up with a spread. Every so often it looks away (it dims).
## Counter: shoot while it is looking away.

## Physics layer of the player's shots.
const PLAYER_SHOTS := 4
const AWAY_TINT := Color(0.55, 0.55, 0.6)

@export var creep_speed := 40.0
@export var sight_range := 220.0
@export var watch_time := 2.0
@export var away_time := 1.2
@export var hide_time := 1.0
@export var spread_shots := 3
@export var spread_angle := 30.0

enum Mode { WATCH, AWAY, HIDE }


## Fan offsets in degrees: `count` shots `angle` degrees apart, centered on the aim.
static func spread_offsets(count: int, angle: float) -> Array[float]:
	var offsets: Array[float] = []
	for i in count:
		offsets.append((i - (count - 1) / 2.0) * angle)
	return offsets


## Next mode and its timer. `t` is time left in `mode`; `sees_shot` means a player shot is in range.
static func next_mode(mode: Mode, t: float, sees_shot: bool, watch: float, away: float, hide: float) -> Array:
	if mode == Mode.WATCH and sees_shot:
		return [Mode.HIDE, hide]
	if t > 0.0:
		return [mode, t]
	match mode:
		Mode.WATCH:
			return [Mode.AWAY, away]
		_:
			return [Mode.WATCH, watch]


func begin(enemy: Enemy) -> void:
	var s := state(enemy)
	s["mode"] = Mode.WATCH
	s["t"] = randf() * watch_time  # Out of step, so a squad doesn't look away together.
	var eye := Area2D.new()
	eye.collision_layer = 0
	eye.collision_mask = PLAYER_SHOTS
	eye.monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = sight_range
	shape.shape = circle
	eye.add_child(shape)
	enemy.add_child(eye)
	s["eye"] = eye


func tick(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	enemy.fire_cooldown = 9.0  # The brain stays quiet; the volley is ours.
	if enemy.state == Enemy.State.DIVING and is_instance_valid(enemy.target):
		var to := enemy.target.global_position - enemy.global_position
		enemy.position += to.limit_length(creep_speed * delta)
	var was: Mode = s["mode"]
	var sees: bool = (s["eye"] as Area2D).has_overlapping_areas()
	var next := next_mode(was, s["t"] - delta, sees, watch_time, away_time, hide_time)
	s["mode"] = next[0]
	s["t"] = next[1]
	if next[0] == was:
		return
	enemy.set_shielded(next[0] == Mode.HIDE)
	enemy.modulate = AWAY_TINT if next[0] == Mode.AWAY else Color.WHITE
	if was == Mode.HIDE:
		_volley(enemy)


func _volley(enemy: Enemy) -> void:
	if enemy.state != Enemy.State.DIVING or not is_instance_valid(enemy.target):
		return
	var aim := enemy.predicted_player(0.2)
	for offset in spread_offsets(spread_shots, spread_angle):
		enemy.fire_at(aim, 0.0, offset)
