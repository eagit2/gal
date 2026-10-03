class_name CompanionSystem
extends Node
## Clearing a stage without being touched (shield or hull) drops a companion drone bubble; catching
## it adds a CompanionDrone that stays until it rams an enemy.

const KIND := &"drone"
const TINT := Color(0.6, 1.0, 0.7)
const DRONE := preload("res://scenes/player/companion_drone.gd")

@export var player: Player
var _struck := false


func _ready() -> void:
	EventBus.stage_started.connect(func(_id: StringName) -> void: _struck = false)
	EventBus.ship_struck.connect(func() -> void: _struck = true)
	EventBus.stage_cleared.connect(_on_cleared)
	EventBus.upgrade_bubble_caught.connect(_on_caught)


func _on_cleared(_id: StringName) -> void:
	if not _struck:
		EventBus.upgrade_bubble_requested.emit(KIND, false, "DRONE", TINT)


func _on_caught(kind: StringName) -> void:
	if kind != KIND or not is_instance_valid(player):
		return
	var drone: CompanionDrone = DRONE.new()
	drone.player = player
	drone.entities = get_parent()
	drone.position = player.global_position + CompanionDrone.OFFSET
	get_parent().add_child(drone)
