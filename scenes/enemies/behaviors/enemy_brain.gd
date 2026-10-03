class_name EnemyBrain
extends Resource
## Decides how an enemy attacks once it leaves formation. One brain resource is shared by every
## enemy of a type, so per-enemy state (phase, timers, counters) lives on the Enemy.

## Cruise speed in pixels per second (scaled by stage aggression).
@export var speed := 300.0
## Max turn in radians per second.
@export var turn_rate := 3.0
## Seconds between shots.
@export var fire_interval := 1.0
## Attacks end after this long whatever the brain is doing.
@export var max_time := 9.0


func begin(enemy: Enemy) -> void:
	enemy.set_phase(0)


## Steers the enemy for one frame. Returns true when the attack is over (the enemy flies home).
func tick(_enemy: Enemy, _delta: float) -> bool:
	return true


## Called when the enemy leaves the bottom and reappears at the top. Return true to keep attacking.
func continue_after_wrap(_enemy: Enemy) -> bool:
	return false
