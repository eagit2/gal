class_name Shield
extends Hurtbox
## Auto bubble around the player: always up, absorbs hits (one per layer; a shot or a ram), and
## recharges one layer at a time. The player keeps its own hurtbox invulnerable while it is up.

## The bubble absorbed a hit and is down (visuals can play a pop effect).
signal popped
## The bubble is back up.
signal restored

## Base seconds per layer; GameState.stats[&"shield_recharge"] scales it.
var recharge_time := 12.0
var up := true
var layers := 1
var _max_layers := 1
var _recharge := 0.0
var _reported := -1

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	hurt.connect(_on_hurt)
	_report()


func _physics_process(delta: float) -> void:
	if up:
		return
	_recharge -= delta
	if _recharge <= 0.0:
		up = true
		_visual.visible = true
		restored.emit()
	_report()


## Brings the bubble back up at once (Bulwark).
func restore() -> void:
	if up:
		return
	_recharge = 0.0
	_physics_process(0.0)


## 0 right after popping, 1 when up.
func charge() -> float:
	return 1.0 if up else clampf(1.0 - _recharge / recharge_time, 0.0, 1.0)


func _on_hurt(_hitbox: Hitbox) -> void:
	up = false
	invulnerable = true
	_recharge = recharge_time
	_visual.visible = false
	popped.emit()
	_report()


## Tells the HUD in 10% steps.
func _report() -> void:
	var step := floori(charge() * 10.0)
	if step != _reported:
		_reported = step
		EventBus.shield_changed.emit(charge())
