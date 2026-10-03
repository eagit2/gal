class_name Mimic
extends Node2D
## Looks like a scrap pile but doesn't spin. When the player comes close it lunges at them; contact
## costs a life. Shot, it leaves real scrap. Counter: watch for the pile that doesn't spin.

const FALL_SPEED := 85.0
const SWAY := 22.0
const NOTICE := 150.0
const LUNGE_SPEED := 430.0
const LUNGE_TIME := 1.4
const BOTTOM := 1000.0
const SCRAP := 3

var player: Player
var _t := randf() * TAU
var _x := 0.0
var _lunge := -1.0
var _dir := Vector2.DOWN


func _ready() -> void:
	_x = position.x
	$Health.died.connect(_on_died)
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: queue_free())


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	_t += delta
	if _lunge >= 0.0:
		_lunge += delta
		position += _dir * LUNGE_SPEED * delta
		$Visual.rotation = sin(_t * 40.0) * 0.3
		if _lunge > LUNGE_TIME:
			_lunge = -2.0  # spent: fall from here
			_x = position.x
	else:
		position.y += FALL_SPEED * delta
		position.x = _x + sin(_t * 2.2) * SWAY
		if _lunge > -1.5 and is_instance_valid(player) and player.alive and position.distance_to(player.global_position) < NOTICE:
			_lunge = 0.0
			_dir = position.direction_to(player.global_position)
	if position.y > BOTTOM or position.y < -60.0:
		queue_free()


func _on_died() -> void:
	EventBus.scrap_dropped.emit(global_position, SCRAP)
	queue_free()
