class_name Shield
extends Hurtbox
## Auto bubble around the player, only while a shield part is fitted (GameState.stats[&"shield"] > 0).
## It holds 1 + shield_layers layers; each hit (a shot or a ram) takes one, and the bubble drops when
## the last one goes. Layers recharge one at a time. The player keeps its own hurtbox invulnerable
## while the bubble is up; with no shield part fitted there is no bubble and hits land directly.

## The bubble absorbed its last layer and is down (visuals can play a pop effect).
signal popped
## The bubble is back up.
signal restored

## Base seconds per layer; GameState.stats[&"shield_recharge"] scales it.
var recharge_time := 12.0
## A shield part is fitted.
var enabled := true
var up := true
var layers := 1
var _max_layers := 1
var _recharge := 0.0
var _reported := -1

@onready var _visual: Node2D = $Visual


## Layers a bubble holds with `extra` from shield_layers.
static func max_layers_for(extra: int) -> int:
	return 1 + maxi(extra, 0)


func _ready() -> void:
	hurt.connect(_on_hurt)
	EventBus.stats_changed.connect(_sync_stats)
	_sync_stats()


func _sync_stats() -> void:
	var stats := GameState.stats
	enabled = int(stats.get(&"shield", 0)) > 0
	_max_layers = max_layers_for(int(stats.get(&"shield_layers", 0)))
	if not enabled:
		up = false
		layers = 0
		invulnerable = true
		_visual.visible = false
		set_physics_process(false)
		EventBus.shield_changed.emit(-1.0)
		_reported = -1
		return
	set_physics_process(true)
	if up:
		layers = _max_layers
	_visual.visible = up
	_report()


func _cycle_time() -> float:
	return recharge_time * float(GameState.stats.get(&"shield_recharge", 1.0))


func _physics_process(delta: float) -> void:
	if layers >= _max_layers:
		return
	_recharge -= delta
	if _recharge <= 0.0:
		layers += 1
		_recharge = _cycle_time() if layers < _max_layers else 0.0
		if not up:
			up = true
			_visual.visible = true
			restored.emit()
	_report()


## Brings every layer back at once (Bulwark).
func restore() -> void:
	if not enabled or layers >= _max_layers:
		return
	layers = _max_layers - 1
	_recharge = 0.0
	_physics_process(0.0)


## 0 right after the bubble drops, 1 when every layer is up.
func charge() -> float:
	if not enabled:
		return 0.0
	var partial := 0.0 if layers >= _max_layers else clampf(1.0 - _recharge / _cycle_time(), 0.0, 1.0)
	return clampf((layers + partial) / _max_layers, 0.0, 1.0)


func _on_hurt(_hitbox: Hitbox) -> void:
	if not enabled:
		return
	if layers >= _max_layers:
		_recharge = _cycle_time()
	layers -= 1
	if layers > 0:
		_report()
		return
	up = false
	invulnerable = true
	_visual.visible = false
	popped.emit()
	_report()


## Tells the HUD in 10% steps (-1: no shield fitted).
func _report() -> void:
	var step := floori(charge() * 10.0)
	if step != _reported:
		_reported = step
		EventBus.shield_changed.emit(charge())
