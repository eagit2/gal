class_name Hud
extends CanvasLayer
## Score, lives, high score, shield, combo meters and the active combo mode, upgrade toasts,
## and center messages (pause, game over).

const METER_SIZE := Vector2(74, 7)
const METER_LABELS := {&"overdrive": "OD", &"lock_on": "LK", &"chain_reaction": "CH", &"graze": "GZ"}

@onready var _score: Label = $Score
@onready var _lives: Label = $Lives
@onready var _high: Label = $HighScore
@onready var _message: Label = $Message
@onready var _banner: Label = $Banner
@onready var _shield: Label = $Shield
@onready var _meters: VBoxContainer = $Meters
@onready var _mode: Label = $Mode
@onready var _mode_bar: ProgressBar = $ModeBar
@onready var _toast: Label = $Toast
var _banner_tween: Tween
var _mode_tween: Tween
var _toast_tween: Tween
var _bars := {}  # combo id -> ProgressBar


func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.lives_changed.connect(set_lives)
	EventBus.combo_meter_changed.connect(_on_meter_changed)
	EventBus.combo_started.connect(_on_combo_started)
	EventBus.combo_ended.connect(_on_combo_ended)
	EventBus.upgrade_picked.connect(_on_upgrade_picked)
	EventBus.synergy_activated.connect(func(s: SynergyDef) -> void: show_toast("SYNERGY: %s" % s.display_name.to_upper(), Color(1, 0.55, 0.95)))
	EventBus.medal_earned.connect(func(m: MedalDef, credits: int) -> void: show_toast("MEDAL: %s  +%d CREDITS" % [m.display_name.to_upper(), credits], Color(0.95, 0.77, 0.43)))
	EventBus.run_ended.connect(_on_run_ended)
	_build_meters()
	_mode.visible = false
	_mode_bar.visible = false
	_toast.visible = false
	_on_score_changed(GameState.score)
	set_lives(GameState.lives)
	_high.text = "HI %d" % SaveManager.data["high_score"]
	show_message("")
	_banner.visible = false


func set_lives(lives: int) -> void:
	_lives.text = "SHIPS %d" % lives


func show_message(text: String) -> void:
	_message.text = text
	_message.visible = text != ""


## Text shown briefly mid-screen (stage names, challenge results).
func show_banner(text: String, duration: float) -> void:
	if _banner_tween:
		_banner_tween.kill()
	_banner.text = text
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(duration)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)
	_banner_tween.tween_callback(_banner.hide)


func _on_score_changed(score: int) -> void:
	_score.text = "%06d" % score


func _on_shield_changed(charge: float) -> void:
	_shield.text = "SHIELD UP" if charge >= 1.0 else "SHIELD %d%%" % floori(charge * 100.0)
	_shield.modulate.a = 1.0 if charge >= 1.0 else 0.55


## Short notice mid-screen (upgrade gained, synergy unlocked).
func show_toast(text: String, color := Color.WHITE) -> void:
	if _toast_tween:
		_toast_tween.kill()
	_toast.text = text
	_toast.modulate = color
	_toast.visible = true
	_toast_tween = create_tween().set_ignore_time_scale(true)
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)


func _build_meters() -> void:
	for combo in ComboTracker.COMBOS:
		if not METER_LABELS.has(combo.id):
			continue
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = METER_LABELS[combo.id]
		label.add_theme_font_size_override(&"font_size", 12)
		label.custom_minimum_size.x = 22
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = METER_SIZE
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.max_value = 1.0
		var fill := StyleBoxFlat.new()
		fill.bg_color = combo.color
		var back := StyleBoxFlat.new()
		back.bg_color = Color(1, 1, 1, 0.12)
		bar.add_theme_stylebox_override(&"fill", fill)
		bar.add_theme_stylebox_override(&"background", back)
		row.add_child(bar)
		_meters.add_child(row)
		_bars[combo.id] = bar


func _on_meter_changed(id: StringName, fill: float) -> void:
	if _bars.has(id):
		_bars[id].value = fill


func _on_combo_started(combo: ComboDef, chain: int) -> void:
	_mode.text = combo.display_name + ("  x%d" % chain if chain > 1 else "")
	_mode.modulate = combo.color
	_mode.visible = true
	_mode_bar.visible = true
	_mode_bar.modulate = combo.color
	_mode_bar.value = 1.0
	if _mode_tween:
		_mode_tween.kill()
	_mode_tween = create_tween().set_ignore_time_scale(true)
	_mode_tween.tween_property(_mode_bar, "value", 0.0, combo.duration)


func _on_combo_ended(_combo: ComboDef) -> void:
	_mode.visible = false
	_mode_bar.visible = false


func _on_upgrade_picked(id: StringName) -> void:
	var upgrade := GameState.POOL.find(id)
	if upgrade:
		show_toast("+ " + upgrade.display_name.to_upper(), UpgradePick.RARITY_COLORS[upgrade.rarity])


func _on_run_ended(_victory: bool) -> void:
	if Hangar.run_earned > 0:
		show_toast("+%d HANGAR CREDITS" % Hangar.run_earned, Color(0.95, 0.77, 0.43))
