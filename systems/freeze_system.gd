class_name FreezeSystem
extends Node
## Cryo Pulse: a per-stage charge (stat freeze_charges) that fires on its own when danger crowds
## the ship, freezing every enemy and enemy shot for freeze_time seconds. Frozen enemies can still
## be shot. Other systems check GameState.freeze_left.

## Enemies or enemy shots this close to the ship count as danger.
const DANGER_RADIUS := 110.0
## How many of them in that radius set it off.
const DANGER_COUNT := 4

@export var player: Player
var charges := 0


func _ready() -> void:
	EventBus.stage_started.connect(func(_id: StringName) -> void: refill())


func _exit_tree() -> void:
	GameState.freeze_left = 0.0


func _physics_process(delta: float) -> void:
	if GameState.freeze_left <= 0.0:
		if charges > 0 and player and player.alive and Threat.count(get_tree(), player.global_position, DANGER_RADIUS) >= DANGER_COUNT:
			trigger()
		return
	GameState.freeze_left -= delta / Engine.time_scale
	if GameState.freeze_left <= 0.0:
		GameState.freeze_left = 0.0
		EventBus.freeze_ended.emit()


func refill() -> void:
	charges = int(GameState.stats[&"freeze_charges"])
	EventBus.freeze_charges_changed.emit(charges)


func trigger() -> void:
	if charges <= 0 or GameState.freeze_left > 0.0:
		return
	charges -= 1
	GameState.freeze_left = GameState.stats[&"freeze_time"]
	EventBus.freeze_charges_changed.emit(charges)
	EventBus.freeze_started.emit(GameState.freeze_left)
