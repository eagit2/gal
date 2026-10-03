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
var _picks := 0
var _combos: Array[StringName] = []
var _pick_wait := 0


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
	bus.upgrade_picked.connect(func(_id: StringName) -> void: _picks += 1)
	bus.combo_started.connect(func(c: Resource, _chain: int) -> void: _combos.append(c.get("id")))
	root.get_node("StyleDirector").style_changed.connect(func(t: ThemeDef) -> void: _styles.append(t.id))


func _process(_delta: float) -> bool:
	_frame += 1
	Input.action_press("fire")  # Actions are registered by the Controls autoload after _initialize.
	# Pick the first card after a short look, like a player would.
	# Untyped: naming game classes here would compile them before the autoloads exist.
	var pick: Node = _game.get_node("UpgradePick")
	_pick_wait = _pick_wait + 1 if pick.call("is_open") else 0
	if _pick_wait == 40:
		pick.call("choose", 0)
	var right := (_frame / 90) % 2 == 0
	Input.action_release("move_left" if right else "move_right")
	Input.action_press("move_right" if right else "move_left")
	if _frame < _frames:
		return false
	var state := root.get_node("GameState")
	print("kills=%d hits=%d stages_cleared=%d score=%d lives=%d upgrades=%d %s combos=%s styles=%s" % [_kills, _hits, _stages_cleared, state.score, state.lives, _picks, state.upgrades, _combos, _styles])
	var ok: bool = _kills > 0 and state.score > 0
	if not ok:
		printerr("SMOKE FAIL: no kills or score")
	_game.free()
	quit(0 if ok else 1)
	return true
