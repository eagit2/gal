extends Node
## Meta progress: hangar credits and owned node ranks (stored in SaveManager), the permanent
## effects they give every run, and stage medal payouts.

const TREE: HangarTree = preload("res://data/hangar/hangar_tree.tres")

## Credits earned by medals in the current run (for the game over screen).
var run_earned := 0
var _paid: Array[StringName] = []  # medal ids already paid this run
var _tracker := MedalTracker.new()


func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.stage_started.connect(_on_stage_started)
	EventBus.stage_cleared.connect(_on_stage_cleared)
	EventBus.shot_fired.connect(func() -> void: _tracker.shots += 1)
	EventBus.shot_hit.connect(func() -> void: _tracker.hits += 1)
	EventBus.bullet_grazed.connect(func(_p: Vector2) -> void: _tracker.grazes += 1)
	EventBus.player_died.connect(func(_l: int) -> void: _tracker.ships_lost += 1)
	EventBus.enemy_escaped.connect(func(_e: Node2D) -> void: _tracker.escapes += 1)
	apply()


func credits() -> int:
	return int(SaveManager.data["currency"])


func ranks() -> Dictionary:
	return SaveManager.data["hangar"]


func rank_of(id: StringName) -> int:
	return HangarRules.rank_of(ranks(), id)


func can_buy(node: HangarNodeDef) -> bool:
	return HangarRules.can_buy(node, ranks(), credits())


## Spends credits on the next rank of `node`. Returns false when it can't be bought.
func buy(node: HangarNodeDef) -> bool:
	if not can_buy(node):
		return false
	_add_credits(-HangarRules.next_cost(node, ranks()))
	ranks()[String(node.id)] = rank_of(node.id) + 1
	SaveManager.save()
	apply()
	EventBus.hangar_changed.emit()
	return true


## Pushes the owned ranks into the run stats.
func apply() -> void:
	GameState.set_meta_effects(HangarRules.effects(TREE, ranks()))


func _add_credits(amount: int) -> void:
	SaveManager.data["currency"] = credits() + amount
	EventBus.credits_changed.emit(credits())


func _on_run_started(_difficulty: StringName) -> void:
	run_earned = 0
	_paid.clear()
	apply()


func _on_stage_started(stage_id: StringName) -> void:
	var path := "res://data/stages/%s.tres" % stage_id
	var stage: StageDef = load(path) if ResourceLoader.exists(path) else null
	_tracker = MedalTracker.new(stage.medal if stage else null)


func _on_stage_cleared(_stage_id: StringName) -> void:
	var medal := _tracker.medal
	if not _tracker.earned() or medal.id in _paid:
		return
	_paid.append(medal.id)
	var amount := HangarRules.payout(medal, _currency_mult())
	run_earned += amount
	_add_credits(amount)
	SaveManager.save()
	EventBus.medal_earned.emit(medal, amount)


func _currency_mult() -> float:
	var path := "res://data/difficulty/%s.tres" % GameState.difficulty_id
	return (load(path) as DifficultyDef).score_multiplier if ResourceLoader.exists(path) else 1.0
