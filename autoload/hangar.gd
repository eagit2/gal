extends Node
## Meta progress: scrap (the hangar currency, saved as "currency"), owned frames, modules and pilots,
## and the loadout (stored in the meta save beside the run checkpoint), the permanent effects they give
## every run, module AP from kills, scrap pickups and stage medal payouts.

const CATALOG: ModuleCatalog = preload("res://data/hangar/catalog.tres")
## AP every equipped module earns per kill.
const AP_PER_KILL := 1

## Scrap earned in the current run, from piles and medals (for the game over screen).
var run_earned := 0
var _paid: Array[StringName] = []  # medal ids already paid this run
var _tracker := MedalTracker.new()
var _kills := 0  # kills not yet turned into AP
var _power_effects: Array[Dictionary] = []  # an active pilot power (Overclock)


func _ready() -> void:
	SaveManager.data["hangar"] = Loadout.normalize(SaveManager.data.get("hangar"), CATALOG)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(func(_v: bool) -> void: _grant_ap())
	EventBus.stage_started.connect(_on_stage_started)
	EventBus.stage_cleared.connect(_on_stage_cleared)
	EventBus.run_ended.connect(func(_v: bool) -> void: SaveManager.save())
	EventBus.enemy_killed.connect(func(_e: Node2D, _p: Vector2, _s: int) -> void: _kills += 1)
	EventBus.shot_fired.connect(func() -> void: _tracker.shots += 1)
	EventBus.shot_hit.connect(func() -> void: _tracker.hits += 1)
	EventBus.bullet_grazed.connect(func(_p: Vector2) -> void: _tracker.grazes += 1)
	EventBus.player_died.connect(func(_l: int) -> void: _tracker.ships_lost += 1)
	EventBus.enemy_escaped.connect(func(_e: Node2D) -> void: _tracker.escapes += 1)
	apply()


func state() -> Dictionary:
	return SaveManager.data["hangar"]


func credits() -> int:
	return int(SaveManager.data["currency"])


func frame() -> FrameDef:
	return Loadout.frame_of(CATALOG, state())


func pilot() -> PilotDef:
	return Loadout.pilot_of(CATALOG, state())


func owns_pilot(id: StringName) -> bool:
	return String(id) in (state()["pilots"] as Array)


## Buys the pilot if needed, then flies with them. Returns false when it can't be afforded.
func choose_pilot(def: PilotDef) -> bool:
	if not owns_pilot(def.id):
		if def.cost > credits():
			return false
		(state()["pilots"] as Array).append(String(def.id))
		_add_credits(-def.cost)
	state()["pilot"] = String(def.id)
	_changed()
	return true


## Temporary effects from a pilot power, on top of the loadout. Empty to end them.
func set_power_effects(effects: Array[Dictionary]) -> void:
	_power_effects = effects
	apply()


func owns_frame(id: StringName) -> bool:
	return String(id) in (state()["frames"] as Array)


func buy_module(def: ModuleDef) -> bool:
	if not Loadout.in_shop(CATALOG, state(), def) or def.cost > credits():
		return false
	(state()["modules"] as Array).append({"id": String(def.id), "ap": 0, "born": false})
	_spend(def.cost)
	return true


func buy_frame(def: FrameDef) -> bool:
	if owns_frame(def.id) or def.cost > credits():
		return false
	(state()["frames"] as Array).append(String(def.id))
	Loadout.set_frame(CATALOG, state(), def.id)
	_spend(def.cost)
	return true


func use_frame(id: StringName) -> void:
	if owns_frame(id):
		Loadout.set_frame(CATALOG, state(), id)
		_changed()


## Puts module `index` in `slot`; -1 empties it.
func equip(slot: int, index: int) -> void:
	Loadout.equip(state(), slot, index)
	_changed()


## Pushes the loadout into the run stats.
func apply() -> void:
	GameState.set_meta_effects(Loadout.effects(CATALOG, state()) + _power_effects)


func _spend(amount: int) -> void:
	_add_credits(-amount)
	_changed()


func _changed() -> void:
	SaveManager.save()
	apply()
	EventBus.hangar_changed.emit()


## A scrap pile was collected: scales it by difficulty and scrap_mult and banks it. Saved at stage
## clear and run end, not on every pile.
func add_scrap(amount: int, at := Vector2.ZERO) -> void:
	var scaled := maxi(1, roundi(amount * _currency_mult()))
	run_earned += scaled
	_add_credits(scaled)
	EventBus.scrap_collected.emit(scaled, at)


func _add_credits(amount: int) -> void:
	SaveManager.data["currency"] = credits() + amount
	EventBus.credits_changed.emit(credits())


func _grant_ap() -> void:
	if _kills == 0:
		return
	var mastered := Loadout.add_ap(CATALOG, state(), _kills * AP_PER_KILL)
	_kills = 0
	_changed()
	for def in mastered:
		EventBus.module_mastered.emit(def)


func _on_run_started(_difficulty: StringName) -> void:
	run_earned = 0
	_kills = 0
	_power_effects = []
	_paid.clear()
	apply()


func _on_stage_started(stage_id: StringName) -> void:
	var path := "res://data/stages/%s.tres" % stage_id
	var stage: StageDef = load(path) if ResourceLoader.exists(path) else null
	_tracker = MedalTracker.new(stage.medal if stage else null)


func _on_stage_cleared(_stage_id: StringName) -> void:
	_grant_ap()
	var medal := _tracker.medal
	if not _tracker.earned() or medal.id in _paid:
		SaveManager.save()
		return
	_paid.append(medal.id)
	var amount := roundi(medal.currency * _currency_mult())
	run_earned += amount
	_add_credits(amount)
	SaveManager.save()
	EventBus.medal_earned.emit(medal, amount)


## Difficulty multiplier times the scrap_mult stat.
func _currency_mult() -> float:
	var path := "res://data/difficulty/%s.tres" % GameState.difficulty_id
	var difficulty := (load(path) as DifficultyDef).score_multiplier if ResourceLoader.exists(path) else 1.0
	return difficulty * GameState.stats[&"scrap_mult"]
