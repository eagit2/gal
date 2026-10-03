class_name ComboTracker
extends Node
## Fills the combo meters from play and runs combo modes (docs/combo-styles.md):
## Overdrive (kill streaks), Lock-On (accuracy), Chain Reaction (multi-kills and diver kills),
## Graze (near misses), and Arcade '81 (ship rescue, triggered directly).
## One mode at a time; a full meter waiting when a mode ends chains into it for a higher multiplier.

const COMBOS: Array[ComboDef] = [
	preload("res://data/combos/overdrive.tres"),
	preload("res://data/combos/lock_on.tres"),
	preload("res://data/combos/chain_reaction.tres"),
	preload("res://data/combos/graze.tres"),
	preload("res://data/combos/arcade_81.tres"),
]
const KILL_WINDOW := 1.2
## Kills this close together count as one multi-kill burst.
const BURST_WINDOW := 0.25
const BURST_SIZE := 3
const DIVER_KILL_POINTS := 0.5

var difficulty: DifficultyDef
var active: ComboDef
## 1 for a mode triggered from play, +1 for each mode chained straight after another.
var chain := 0
var time_left := 0.0
var meters := {}  # combo id -> points
var _idle := {}  # combo id -> seconds since the meter last gained
var _clock := 0.0
var _last_kill := -100.0
var _burst_start := -100.0
var _burst := 0


func _ready() -> void:
	for combo in COMBOS:
		meters[combo.id] = 0.0
		_idle[combo.id] = 0.0
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.shot_hit.connect(func() -> void: gain(&"lock_on", 1.0))
	EventBus.shot_missed.connect(func() -> void: _set_meter(&"lock_on", 0.0))
	EventBus.bullet_grazed.connect(_on_grazed)
	EventBus.ship_rescued.connect(func() -> void: trigger(&"arcade_81"))


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	StyleDirector.set_combo_style(&"")


func _physics_process(delta: float) -> void:
	var real_delta := delta / Engine.time_scale
	_clock += real_delta
	for combo in COMBOS:
		_idle[combo.id] += real_delta
		if _idle[combo.id] > combo.decay_delay and meters[combo.id] > 0.0:
			_set_meter(combo.id, maxf(0.0, meters[combo.id] - combo.decay_rate * threshold(combo) * real_delta))
	if active:
		time_left -= real_delta
		if time_left <= 0.0:
			_end()


func threshold(combo: ComboDef) -> float:
	return combo.threshold * (difficulty.combo_threshold if difficulty else 1.0)


## Score multiplier from style chains.
func multiplier() -> int:
	return chain if active else 1


func gain(id: StringName, points: float) -> void:
	if active and active.id == id:
		return
	var combo := _find(id)
	_idle[id] = 0.0
	_set_meter(id, minf(meters[id] + points, threshold(combo)))
	if not active and meters[id] >= threshold(combo):
		_start(combo, 1)


## Starts a mode now (Arcade '81 on rescue), replacing any running mode.
func trigger(id: StringName) -> void:
	if active:
		_finish()
	_start(_find(id), 1)


## Ends any running mode without chaining (game over).
func stop() -> void:
	if active:
		_finish()
	chain = 0


func _on_enemy_killed(node: Node2D, _at: Vector2, _score: int) -> void:
	var window: float = KILL_WINDOW * GameState.stats[&"overdrive_window"]
	if _clock - _last_kill <= window:
		gain(&"overdrive", 1.0)
	_last_kill = _clock
	var chain_gain: float = GameState.stats[&"chain_gain"]
	if _clock - _burst_start > BURST_WINDOW:
		_burst_start = _clock
		_burst = 0
	_burst += 1
	if _burst == BURST_SIZE:
		gain(&"chain_reaction", 1.0 * chain_gain)
	var enemy := node as Enemy
	if enemy and enemy.state == Enemy.State.DIVING:
		gain(&"chain_reaction", DIVER_KILL_POINTS * chain_gain)


func _on_grazed(_at: Vector2) -> void:
	gain(&"graze", GameState.stats[&"graze_gain"])
	var bonus: int = GameState.stats[&"graze_score"]
	if bonus > 0:
		GameState.add_score(bonus)


func _start(combo: ComboDef, chain_level: int) -> void:
	active = combo
	chain = chain_level
	time_left = combo.duration
	_set_meter(combo.id, 0.0)
	GameState.set_combo_effects(combo.effects)
	Engine.time_scale = GameState.stats[&"time_scale"]
	StyleDirector.set_combo_style(combo.style)
	EventBus.combo_started.emit(combo, chain)


func _end() -> void:
	var ended := _finish()
	for combo in COMBOS:
		if combo != ended and combo.threshold > 0.0 and meters[combo.id] >= threshold(combo):
			_start(combo, chain + 1)
			return
	chain = 0


func _finish() -> ComboDef:
	var ended := active
	active = null
	GameState.set_combo_effects([])
	Engine.time_scale = 1.0
	StyleDirector.set_combo_style(&"")
	EventBus.combo_ended.emit(ended)
	return ended


func _set_meter(id: StringName, value: float) -> void:
	if is_equal_approx(meters[id], value):
		return
	meters[id] = value
	var combo := _find(id)
	EventBus.combo_meter_changed.emit(id, value / threshold(combo) if combo.threshold > 0.0 else 0.0)


func _find(id: StringName) -> ComboDef:
	for combo in COMBOS:
		if combo.id == id:
			return combo
	return null
