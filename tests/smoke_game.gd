extends SceneTree
## Headless playthrough: holds fire and sweeps left/right, then checks the game loop works.
## godot --headless --fixed-fps 60 -s res://tests/smoke_game.gd [-- --seconds=S stage=N]
## stage (and the other DevOptions) is read by the game itself: N is 1-based or a stage id.

var _game: Node
var _frame := 0
var _frames := 1800
var _kills := 0
var _hits := 0
var _stages_cleared := 0
var _styles: Array[StringName] = []
var _scrap := 0
var _combos: Array[StringName] = []
var _cutscenes: Array[StringName] = []
var _drops: Array[StringName] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			_frames = int(arg.get_slice("=", 1)) * 60
	_game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(_game)
	var bus := root.get_node("EventBus")
	bus.enemy_killed.connect(func(_e: Node2D, _p: Vector2, _s: int) -> void: _kills += 1)
	bus.player_hit.connect(func() -> void: _hits += 1)
	bus.stage_cleared.connect(func(_id: StringName) -> void: _stages_cleared += 1)
	bus.scrap_collected.connect(func(amount: int, _at: Vector2) -> void: _scrap += amount)
	bus.combo_started.connect(func(c: Resource, _chain: int) -> void: _combos.append(c.get("id")))
	bus.cutscene_finished.connect(func(id: StringName) -> void: _cutscenes.append(id))
	bus.drop_caught.connect(func(kind: StringName, id: StringName, _at: Vector2) -> void: _drops.append(StringName("%s:%s" % [kind, id])))
	root.get_node("StyleDirector").style_changed.connect(func(t: ThemeDef) -> void: _styles.append(t.id))


func _process(_delta: float) -> bool:
	_frame += 1
	Input.action_press("fire")  # Actions are registered by the Controls autoload after _initialize.
	var right := (_frame / 90) % 2 == 0
	Input.action_release("move_left" if right else "move_right")
	Input.action_press("move_right" if right else "move_left")
	if _frame < _frames:
		return false
	var state := root.get_node("GameState")
	print("kills=%d hits=%d stages_cleared=%d score=%d lives=%d scrap=%d combos=%s styles=%s cutscenes=%s drops=%s" % [_kills, _hits, _stages_cleared, state.score, state.lives, _scrap, _combos, _styles, _cutscenes, _drops])
	var ok: bool = _kills > 0 and state.score > 0
	if not ok:
		printerr("SMOKE FAIL: no kills or score")
	_game.free()
	quit(0 if ok else 1)
	return true
