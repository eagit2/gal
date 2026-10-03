class_name Hud
extends CanvasLayer
## Score, lives, high score, and center messages (pause, game over).

@onready var _score: Label = $Score
@onready var _lives: Label = $Lives
@onready var _high: Label = $HighScore
@onready var _message: Label = $Message
@onready var _banner: Label = $Banner
@onready var _shield: Label = $Shield
var _banner_tween: Tween


func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
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
