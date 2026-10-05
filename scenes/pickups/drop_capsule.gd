class_name DropCapsule
extends Node2D
## A falling item or power-up capsule. Flying into it emits EventBus.drop_caught; it is gone for good
## once it falls off the bottom.

const COLLECT_RADIUS := 30.0
const BOTTOM := 1000.0

var player: Player
## &"powerup", &"part" or &"chip".
var kind: StringName
## Power-up kind (Powerups.KINDS), part id or chip id.
var id: StringName
var speed := Pickup.FALL_SPEED


func setup(drop_kind: StringName, drop_id: StringName) -> void:
	kind = drop_kind
	id = drop_id
	var label := "?"
	var tint := Color(0.8, 0.6, 1.0)
	if kind == &"powerup":
		label = Powerups.LABELS[id]
		tint = Powerups.COLORS[id]
	elif kind == &"chip":
		var chip := Hangar.CATALOG.chip(id)
		label = "C"
		tint = chip.color if chip else tint
	else:
		label = "!"
		tint = Color(1, 0.8, 0.35)
	$Visual.set(&"label", label)
	$Visual.set(&"tint", tint)


func _ready() -> void:
	add_to_group(&"drop_capsules")


func _physics_process(delta: float) -> void:
	position.y += speed * delta
	if is_instance_valid(player) and player.alive and player.global_position.distance_to(global_position) <= COLLECT_RADIUS:
		EventBus.drop_caught.emit(kind, id, global_position)
		queue_free()
	elif position.y > BOTTOM:
		queue_free()
