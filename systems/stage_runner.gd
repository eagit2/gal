class_name StageRunner
extends Node
## Spawns a StageDef's waves on their timeline and reports when every enemy is dead or gone.

signal waves_done
signal finished(kills: int, total: int)

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const SPAWN_INTERVAL := 0.14

var formation: Formation
var target: Player
var entities: Node2D
var stage: StageDef
var _difficulty: DifficultyDef
var _queue: Array[Dictionary] = []
var _time := 0.0
var _kills := 0
var _total := 0
var _running := false


func _ready() -> void:
	EventBus.enemy_killed.connect(func(_e: Node2D, _p: Vector2, _s: int) -> void: _kills += 1)


func start(stage_def: StageDef, difficulty: DifficultyDef) -> void:
	stage = stage_def
	_difficulty = difficulty
	_queue = build_queue(stage_def)
	_total = _queue.size()
	_time = 0.0
	_kills = 0
	_running = true
	formation.breathing = false


## Flattens waves into a spawn list sorted by time. Static so tests can check stage data.
static func build_queue(stage_def: StageDef) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
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
	if _queue.is_empty() and get_tree().get_nodes_in_group(&"enemies").is_empty():
		_running = false
		finished.emit(_kills, _total)


func _spawn(entry: Dictionary) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(entry["enemy"], _difficulty, entry["path"], entry["slot"], formation)
	enemy.target = target
	enemy.entities = entities
	entities.add_child(enemy)
