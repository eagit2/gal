class_name Formation
extends Node2D
## The grid enemies settle into. Sways side to side while waves enter, then breathes (expands and contracts).

const COLUMNS := 10
const ROWS := 5
const STEP := Vector2(46, 44)
const TOP := 120.0
const SWAY := 34.0
const BREATH := 0.1

## Set by the stage runner once every wave has been spawned.
var breathing := false
var _t := 0.0
var _blend := 0.0


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	_t += delta
	_blend = move_toward(_blend, 1.0 if breathing else 0.0, delta * 0.5)


func slot_position(slot: Vector2i) -> Vector2:
	var spread := 1.0 + BREATH * sin(_t * 1.6) * _blend
	var sway := SWAY * sin(_t * 0.9) * (1.0 - _blend)
	var x := 270.0 + (slot.x - (COLUMNS - 1) / 2.0) * STEP.x * spread + sway
	var y := TOP + slot.y * STEP.y * (1.0 + (spread - 1.0) * 0.6)
	return Vector2(x, y)
