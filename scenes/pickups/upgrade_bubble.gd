class_name UpgradeBubble
extends Node2D
## A combo or triggered extra waiting to be caught. Falls with a sway; flying into it emits
## EventBus.upgrade_bubble_caught, letting it fall off the bottom emits upgrade_bubble_lost.

const COLLECT_RADIUS := 34.0
const SWAY := 18.0
const BOTTOM := 1000.0

var player: Player
var kind: StringName
var speed := 85.0
var _t := randf() * TAU
var _x := 0.0


func setup(bubble_kind: StringName, fall_speed: float, label: String, tint: Color) -> void:
	kind = bubble_kind
	speed = fall_speed
	$Visual.set(&"label", label)
	$Visual.set(&"tint", tint)


func _ready() -> void:
	_x = position.x
	add_to_group(&"upgrade_bubbles")


func _physics_process(delta: float) -> void:
	_t += delta
	position.y += speed * delta
	position.x = _x + sin(_t * 1.8) * SWAY
	if is_instance_valid(player) and player.alive and player.global_position.distance_to(global_position) <= COLLECT_RADIUS:
		EventBus.upgrade_bubble_caught.emit(kind)
		queue_free()
	elif position.y > BOTTOM:
		EventBus.upgrade_bubble_lost.emit(kind)
		queue_free()
