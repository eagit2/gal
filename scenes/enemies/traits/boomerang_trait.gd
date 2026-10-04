class_name BoomerangTrait
extends EnemyTrait
## Throws shots that curve out and come back to where they were thrown. Counter: dodge twice, once
## going out and once coming back.

const SHOT := preload("res://scenes/projectiles/boomerang_shot.tscn")
## Total bend of the outbound leg, radians.
const SWEEP := 1.7
## Angle between the shots of one volley, degrees.
const FAN := 22.0

@export var interval := 2.2
@export var shots := 2
@export var range := 220.0
@export var return_speed := 320.0


## Launch angle offsets (degrees) for a volley of `count` shots `fan` degrees apart.
static func fan_offsets(count: int, fan: float) -> Array[float]:
	var offsets: Array[float] = []
	for i in count:
		offsets.append((i - (count - 1) / 2.0) * fan)
	return offsets


func tick(enemy: Enemy, delta: float) -> void:
	if enemy.state != Enemy.State.DIVING:
		state(enemy)["t"] = interval * 0.5
		return
	var t: float = state(enemy).get("t", interval * 0.5) - delta
	if t <= 0.0:
		_throw(enemy)
		t = interval
	state(enemy)["t"] = t


func _throw(enemy: Enemy) -> void:
	var player := enemy.target
	if not is_instance_valid(player) or not player.alive or enemy.global_position.y > player.global_position.y - 80.0:
		return
	var speed := enemy.def.bullet_speed * enemy.difficulty.enemy_bullet_speed
	var aim := enemy.global_position.direction_to(enemy.predicted_player(0.3))
	var offsets := fan_offsets(shots, FAN)
	for i in offsets.size():
		var shot: BoomerangShot = Pools.acquire(SHOT)
		var direction := aim.rotated(deg_to_rad(offsets[i]))
		shot.launch(enemy.entities, enemy.global_position + direction * 14.0, direction * speed, 1, SHOT)
		var side := 1.0 if i % 2 == 0 else -1.0
		shot.throw(range, return_speed, side * BoomerangShot.curve_rate(range, speed, SWEEP))
