extends SceneTree
## Headless playthrough: holds fire for 30 simulated seconds and checks the game loop works.
## godot --headless --fixed-fps 60 -s res://tests/smoke_game.gd

const FRAMES := 1800

var _game: Node
var _frame := 0
var _kills := 0
var _hits := 0


func _initialize() -> void:
	_game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(_game)
	root.get_node("EventBus").enemy_killed.connect(func(_e: Node2D, _p: Vector2, _s: int) -> void: _kills += 1)
	root.get_node("EventBus").player_hit.connect(func() -> void: _hits += 1)


func _process(_delta: float) -> bool:
	_frame += 1
	Input.action_press("fire")  # Actions are registered by the Controls autoload after _initialize.
	# Sweep left and right so the ship covers the whole formation.
	var right := (_frame / 120) % 2 == 0
	Input.action_release("move_left" if right else "move_right")
	Input.action_press("move_right" if right else "move_left")
	if _frame < FRAMES:
		return false
	var state := root.get_node("GameState")
	print("kills=%d hits=%d score=%d lives=%d wave=%d" % [_kills, _hits, state.score, state.lives, _game.wave])
	var ok: bool = _kills > 0 and state.score > 0
	if not ok:
		printerr("SMOKE FAIL: no kills or score")
	_game.free()
	quit(0 if ok else 1)
	return true
