class_name FreezeSystem
extends Node
## Cryo Pulse (Frost Nova): a per-stage charge (stat freeze_charges). When danger crowds the ship a
## charge drops an upgrade bubble (BubbleSystem); catching it chills every enemy on screen, slowing
## them by NOVA_SLOW for freeze_time seconds (Eric: 90% for 3 s). Nothing freezes; enemy shots keep
## flying. A missed bubble wastes the charge.

## Enemies or enemy shots this close to the ship count as danger.
const DANGER_RADIUS := 110.0
## How many of them in that radius set it off.
const DANGER_COUNT := 4
const NOVA_SLOW := 0.9
const KIND := &"cryo"
const TINT := Color(0.55, 0.85, 1.0)

@export var player: Player
var charges := 0
var _pending := false
var _nova_left := 0.0


func _ready() -> void:
	EventBus.stage_started.connect(func(_id: StringName) -> void: refill())
	EventBus.upgrade_bubble_caught.connect(_on_caught)
	EventBus.upgrade_bubble_lost.connect(func(kind: StringName) -> void: _pending = _pending and kind != KIND)


func _physics_process(delta: float) -> void:
	if _nova_left > 0.0:
		_nova_left -= delta / Engine.time_scale
		if _nova_left <= 0.0:
			EventBus.freeze_ended.emit()
		return
	if charges > 0 and player and player.alive and Threat.count(get_tree(), player.global_position, DANGER_RADIUS) >= DANGER_COUNT:
		drop_bubble()


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
	EventBus.upgrade_bubble_requested.emit(KIND, false, "NOVA", TINT)


func _on_caught(kind: StringName) -> void:
	if kind != KIND or not _pending:
		return
	_pending = false
	nova()


## Chills every enemy on screen now (the caught bubble).
func nova() -> void:
	var time: float = GameState.stats[&"freeze_time"]
	for node in get_tree().get_nodes_in_group(&"enemies") + get_tree().get_nodes_in_group(&"elites"):
		StatusEffects.of(node).nova(time, NOVA_SLOW)
	_nova_left = time
	EventBus.freeze_started.emit(time)
