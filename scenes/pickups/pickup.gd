class_name Pickup
extends Node2D
## Scrap pile left by a destroyed ship. Falls slowly with a sway; the ship collects it by flying
## over it, and the magnet stat pulls it in. Scrap is the hangar currency.

const FALL_SPEED := 85.0
const SWAY := 22.0
const COLLECT_RADIUS := 30.0
const PULL_SPEED := 460.0
const BOTTOM := 1000.0
const SPIN := 1.6

var player: Player
## Scrap before multipliers. Bigger piles draw bigger.
var amount := 1
var _t := randf() * TAU
var _x := 0.0


func _ready() -> void:
	_x = position.x
	$Visual.scale = Vector2.ONE * clampf(0.8 + amount * 0.08, 0.8, 2.0)


func _physics_process(delta: float) -> void:
	_t += delta
	rotation += SPIN * delta
	if not is_instance_valid(player) or not player.alive:
		_fall(delta)
		return
	var to_player := player.global_position - global_position
	var magnet: float = GameState.stats[&"magnet"]
	if to_player.length() <= COLLECT_RADIUS:
		_collect()
	elif to_player.length() <= magnet:
		position += to_player.normalized() * PULL_SPEED * delta
		_x = position.x
	else:
		_fall(delta)


func _fall(delta: float) -> void:
	position.y += FALL_SPEED * delta
	position.x = _x + sin(_t * 2.2) * SWAY
	if position.y > BOTTOM:
		queue_free()


func _collect() -> void:
	Hangar.add_scrap(amount, global_position)
	queue_free()
