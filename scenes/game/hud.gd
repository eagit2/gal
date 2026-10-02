class_name Hud
extends CanvasLayer
## Score, lives, high score, and center messages (pause, game over).

@onready var _score: Label = $Score
@onready var _lives: Label = $Lives
@onready var _high: Label = $HighScore
@onready var _message: Label = $Message


func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	_on_score_changed(GameState.score)
	set_lives(GameState.lives)
	_high.text = "HI %d" % SaveManager.data["high_score"]
	show_message("")


func set_lives(lives: int) -> void:
	_lives.text = "SHIPS %d" % lives


func show_message(text: String) -> void:
	_message.text = text
	_message.visible = text != ""


func _on_score_changed(score: int) -> void:
	_score.text = "%06d" % score
