class_name FreezeSystem
extends Node
## Cryo Pulse: a per-stage charge (stat freeze_charges). When danger crowds the ship a charge drops
## an upgrade bubble (BubbleSystem); catching it freezes every enemy and enemy shot for freeze_time
## seconds. A missed bubble wastes the charge. Frozen enemies can still be shot. Other systems check
## GameState.freeze_left.

## Enemies or enemy shots this close to the ship count as danger.
const DANGER_RADIUS := 110.0
## How many of them in that radius set it off.
const DANGER_COUNT := 4
const KIND := &"cryo"
const TINT := Color(0.55, 0.85, 1.0)

@export var player: Player
var charges := 0
var _pending := false


func _ready() -> void:
	EventBus.stage_started.connect(func(_id: StringName) -> void: refill())
	EventBus.upgrade_bubble_caught.connect(_on_caught)
	EventBus.upgrade_bubble_lost.connect(func(kind: StringName) -> void: _pending = _pending and kind != KIND)


func _exit_tree() -> void:
	GameState.freeze_left = 0.0


func _physics_process(delta: float) -> void:
	if GameState.freeze_left <= 0.0:
		if charges > 0 and player and player.alive and Threat.count(get_tree(), player.global_position, DANGER_RADIUS) >= DANGER_COUNT:
			drop_bubble()
		return
	GameState.freeze_left -= delta / Engine.time_scale
	if GameState.freeze_left <= 0.0:
		GameState.freeze_left = 0.0
		EventBus.freeze_ended.emit()


func refill() -> void:
	charges = int(GameState.stats[&"freeze_charges"])
	EventBus.freeze_charges_changed.emit(charges)


## Spends a charge on a Cryo bubble.
func drop_bubble() -> void:
	if charges <= 0 or _pending:
		return
	charges -= 1
	_pending = true
	EventBus.freeze_charges_changed.emit(charges)
	EventBus.upgrade_bubble_requested.emit(KIND, false, "CRYO", TINT)


func _on_caught(kind: StringName) -> void:
	if kind != KIND or not _pending:
		return
	_pending = false
	freeze()


## Freezes now (the caught bubble).
func freeze() -> void:
	GameState.freeze_left = GameState.stats[&"freeze_time"]
	EventBus.freeze_started.emit(GameState.freeze_left)
