class_name StageRunner
extends Node
## Spawns a StageDef's waves on their timeline, sends reinforcement squads into empty slots when the
## formation thins out, and reports when every enemy is dead or gone.

signal waves_done
signal finished(kills: int, total: int)

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const ELITE_SCENE := preload("res://scenes/enemies/elite.tscn")
const SPAWN_INTERVAL := 0.14
const REINFORCE_COOLDOWN := 2.5

var formation: Formation
var target: Player
var entities: Node2D
var stage: StageDef
## Dev option: an extra elite for every stage (DevOptions `elite=<id>`).
var extra_elite: EliteDef
## Extra hp multiplier on top of the stage's (rises each time the sector loops).
var hp_ramp := 1.0
var _difficulty: DifficultyDef
var _queue: Array[Dictionary] = []
var _time := 0.0
var _kills := 0
var _total := 0
var _running := false
var _reinforcements_left := 0
var _reinforce_timer := 0.0


func _ready() -> void:
	EventBus.enemy_killed.connect(func(_e: Node2D, _p: Vector2, _s: int) -> void: _kills += 1)


func start(stage_def: StageDef, difficulty: DifficultyDef) -> void:
	stage = stage_def
	_difficulty = difficulty
	_queue = build_queue(stage_def, extra_elite)
	_total = _queue.size()
	_time = 0.0
	_kills = 0
	_reinforcements_left = 0 if stage_def.is_challenge else stage_def.reinforcements
	_reinforce_timer = REINFORCE_COOLDOWN
	_running = true
	formation.breathing = false


## Flattens waves into a spawn list sorted by time. Static so tests can check stage data.
static func build_queue(stage_def: StageDef, extra_elite: EliteDef = null) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	var elites := stage_def.pick_elites()
	if extra_elite and not stage_def.is_challenge:
		elites.push_front(extra_elite)
	for i in elites.size():
		queue.append({"time": (4.0 if extra_elite and i == 0 else stage_def.elite_delay) + i * stage_def.elite_gap, "elite": elites[i]})
	for wave in stage_def.waves:
		for i in wave.count:
			var slot := wave.formation_slots[i] if i < wave.formation_slots.size() else Vector2i(-1, -1)
			if stage_def.is_challenge:
				slot = Vector2i(-1, -1)
			queue.append({"time": wave.delay + i * SPAWN_INTERVAL, "enemy": wave.enemy, "path": wave.entry_path, "slot": slot})
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["time"] < b["time"])
	return queue


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	var spawned_any := false
	while not _queue.is_empty() and _queue[0]["time"] <= _time:
		_spawn(_queue.pop_front())
		spawned_any = true
	if spawned_any and _queue.is_empty():
		formation.breathing = true
		waves_done.emit()
	if _queue.is_empty() and _reinforcements_left > 0:
		_reinforce_timer -= delta
		if _reinforce_timer <= 0.0 and get_tree().get_nodes_in_group(&"enemies").size() < stage.reinforce_below:
			_reinforce()
	if _queue.is_empty() and _reinforcements_left == 0 and get_tree().get_nodes_in_group(&"enemies").is_empty() \
			and get_tree().get_nodes_in_group(&"elites").is_empty():
		_running = false
		finished.emit(_kills, _total)


## Queues one squad of a random wave's enemy type, flying that wave's entry path into free slots.
func _reinforce() -> void:
	_reinforcements_left -= 1
	_reinforce_timer = REINFORCE_COOLDOWN
	var occupied: Array[Vector2i] = []
	for node in get_tree().get_nodes_in_group(&"enemies"):
		occupied.append((node as Enemy).slot)
	var slots := free_slots(occupied)
	slots.shuffle()
	var wave: WaveDef = stage.waves.pick_random()
	for i in mini(stage.reinforcement_size, slots.size()):
		_queue.append({"time": _time + i * SPAWN_INTERVAL, "enemy": wave.enemy, "path": wave.entry_path, "slot": slots[i]})
	_total += mini(stage.reinforcement_size, slots.size())


static func free_slots(occupied: Array[Vector2i]) -> Array[Vector2i]:
	var free: Array[Vector2i] = []
	for row in Formation.ROWS:
		for column in Formation.COLUMNS:
			var slot := Vector2i(column, row)
			if slot not in occupied:
				free.append(slot)
	return free


func _spawn(entry: Dictionary) -> void:
	if entry.has("elite"):
		var elite: Elite = ELITE_SCENE.instantiate()
		elite.setup(entry["elite"], _difficulty, target, entities)
		elite.hp_scale = stage.enemy_hp_mult * hp_ramp
		entities.add_child(elite)
		return
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(entry["enemy"], _difficulty, entry["path"], entry["slot"], formation)
	enemy.target = target
	enemy.entities = entities
	enemy.hp_scale = stage.enemy_hp_mult * hp_ramp
	entities.add_child(enemy)
