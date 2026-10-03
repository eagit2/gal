class_name BubbleSystem
extends Node
## Drops upgrade bubbles near the top of the screen above the ship. Combos and triggered extras
## (Cryo Pulse, the companion drone) only switch on once their bubble is caught. Extras fall at scrap
## pace, combos twice as fast. One bubble per kind at a time; a missed bubble is lost.

const SCENE := preload("res://scenes/pickups/upgrade_bubble.tscn")
const EXTRA_SPEED := Pickup.FALL_SPEED
const COMBO_SPEED := Pickup.FALL_SPEED * 2.0
const TOP := -24.0
const MARGIN := 40.0
const WIDTH := 540.0

@export var player: Player
var _out := {}  # kind -> true while its bubble is falling


func _ready() -> void:
	EventBus.upgrade_bubble_requested.connect(spawn)
	EventBus.upgrade_bubble_caught.connect(func(kind: StringName) -> void: _out.erase(kind))
	EventBus.upgrade_bubble_lost.connect(func(kind: StringName) -> void: _out.erase(kind))


static func fall_speed(is_combo: bool) -> float:
	return COMBO_SPEED if is_combo else EXTRA_SPEED


func is_out(kind: StringName) -> bool:
	return _out.has(kind)


func spawn(kind: StringName, is_combo: bool, label: String, tint: Color) -> void:
	if _out.has(kind):
		return
	_out[kind] = true
	var bubble: UpgradeBubble = SCENE.instantiate()
	var x := player.global_position.x if is_instance_valid(player) else WIDTH * 0.5
	bubble.position = Vector2(clampf(x, MARGIN, WIDTH - MARGIN), TOP)
	bubble.player = player
	get_parent().add_child.call_deferred(bubble)
	bubble.setup(kind, fall_speed(is_combo), label, tint)
