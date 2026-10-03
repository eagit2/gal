class_name Pickup
extends Node2D
## Upgrade capsule dropped by an enemy. Falls slowly with a sway; the ship collects it by flying
## over it. The Tractor Magnet upgrade pulls it in. The upgrade is rolled when collected: utility
## capsules (tinted gold) roll freeze/shield/credit upgrades, the rest roll bullet upgrades.

const FALL_SPEED := 85.0
const SWAY := 22.0
const COLLECT_RADIUS := 30.0
const PULL_SPEED := 460.0
const BOTTOM := 1000.0
## Score instead of an upgrade once every upgrade is maxed.
const MAXED_SCORE := 1000
const UTILITY_TINT := Color(1.0, 0.8, 0.3)

var player: Player
var rarity_bonus := 0
var utility := false
var _t := randf() * TAU
var _x := 0.0


func _ready() -> void:
	_x = position.x
	if utility:
		$Visual.modulate = UTILITY_TINT
		$Visual.scale = Vector2(1.4, 1.4)


func _physics_process(delta: float) -> void:
	_t += delta
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
	var source := UpgradeDef.Source.UTILITY if utility else UpgradeDef.Source.BULLET
	var upgrade := GameState.roll_drop(rarity_bonus, source)
	if upgrade == null and utility:
		upgrade = GameState.roll_drop(rarity_bonus)
	if upgrade:
		GameState.gain_upgrade(upgrade)
	else:
		GameState.add_score(MAXED_SCORE)
	queue_free()
