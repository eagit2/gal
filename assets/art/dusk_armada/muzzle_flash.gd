extends Sprite2D
## Shows a brief flash at the ship's nose each time the player fires.

const SHOW_TIME := 0.05
var _left := 0.0


func _ready() -> void:
	visible = false
	EventBus.shot_fired.connect(_on_shot_fired)


func _on_shot_fired() -> void:
	frame = randi() % hframes
	visible = true
	_left = SHOW_TIME


func _process(delta: float) -> void:
	if _left > 0.0:
		_left -= delta
		visible = _left > 0.0
