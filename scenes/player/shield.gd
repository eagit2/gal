class_name Shield
extends Hurtbox
## Auto bubble around the player: always up, absorbs one hit (a shot or a ram), then recharges.
## The player keeps its own hurtbox invulnerable while the bubble is up.

## The bubble absorbed a hit and is down (visuals can play a pop effect).
signal popped
## The bubble is back up.
signal restored

var recharge_time := 12.0
var up := true
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
