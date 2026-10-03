extends Node
## Meta progress: scrap (the hangar currency, saved as "currency"), owned ships, parts and pilots,
## store stock (new every run), the ship tree, and the loadout (stored in the meta save beside the run checkpoint), the permanent effects they give
## every run, scrap pickups and stage medal payouts.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")

## Scrap earned in the current run, from piles and medals (for the game over screen).
var run_earned := 0
var _paid: Array[StringName] = []  # medal ids already paid this run
var _tracker := MedalTracker.new()
var _power_effects: Array[Dictionary] = []  # an active pilot power (Overclock)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_load_state()
	EventBus.save_slot_loaded.connect(func(_slot: int) -> void: _load_state())
	EventBus.run_started.connect(_on_run_started)
	EventBus.stage_started.connect(_on_stage_started)
	EventBus.stage_cleared.connect(_on_stage_cleared)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.shot_fired.connect(func() -> void: _tracker.shots += 1)
	EventBus.shot_hit.connect(func() -> void: _tracker.hits += 1)
	EventBus.bullet_grazed.connect(func(_p: Vector2) -> void: _tracker.grazes += 1)
	EventBus.player_died.connect(func(_l: int) -> void: _tracker.ships_lost += 1)
	EventBus.enemy_escaped.connect(func(_e: Node2D) -> void: _tracker.escapes += 1)


## Normalizes the active save slot's hangar state and applies it.
func _load_state() -> void:
	SaveManager.data["hangar"] = Loadout.normalize(SaveManager.data.get("hangar"), CATALOG)
	if (state()["stock"] as Array).is_empty():
		HangarStock.roll(CATALOG, state(), _rng)
	apply()
	EventBus.credits_changed.emit(credits())


func state() -> Dictionary:
	return SaveManager.data["hangar"]


func credits() -> int:
	return int(SaveManager.data["currency"])


func ship() -> ShipDef:
	return Loadout.ship_of(CATALOG, state())


func pilot() -> PilotDef:
	return Loadout.pilot_of(CATALOG, state())


## Flies `def` from now on. Returns false while it is locked.
func choose_ship(def: ShipDef) -> bool:
	if not Loadout.unlocked(state(), def):
		return false
	state()["ship"] = String(def.id)
	_changed()
	return true


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


## Buys a part from the store's stock. It is fitted when its mount type has an empty slot.
## Returns false when it isn't in stock or can't be afforded.
func buy_part(def: PartDef) -> bool:
	if def.price() > credits() or not HangarStock.take(state(), def):
		return false
	var fitted := Loadout.preview(CATALOG, state(), def)
	if _fills_empty(fitted, def):
		state()["mounts"] = fitted["mounts"]
	_spend(def.price())
	return true


## Raises one attribute of an owned part. Returns false when maxed or unaffordable.
func upgrade(def: PartDef, attr: StringName) -> bool:
	var price := Loadout.upgrade_price(state(), def, attr)
	if price < 0 or price > credits():
		return false
	Loadout.upgrade(state(), def, attr)
	_spend(price)
	return true


## Buys the next rank of a ship tree node. Returns false when locked, maxed or unaffordable.
func buy_node(node: TreeNodeDef) -> bool:
	var price := ShipTree.price(state(), ship(), node)
	if price > credits() or not ShipTree.buy(CATALOG, state(), node):
		return false
	_spend(price)
	return true


## New store stock for a fee. Returns false when it can't be afforded.
func reroll() -> bool:
	if HangarStock.REROLL_COST > credits():
		return false
	HangarStock.roll(CATALOG, state(), _rng)
	_spend(HangarStock.REROLL_COST)
	return true


## Fits part `id` on `mount` ("" empties it). Returns false when it doesn't fit.
func place(mount: StringName, id: StringName) -> bool:
	if not Loadout.place(CATALOG, state(), mount, id):
		return false
	_changed()
	return true


## Replaces every mount's part at once (the menus check the loadout first).
func set_mounts(mounts: Dictionary) -> void:
	state()["mounts"] = mounts
	_changed()


## Temporary effects from a pilot power, on top of the loadout. Empty to end them.
func set_power_effects(effects: Array[Dictionary]) -> void:
	_power_effects = effects
	apply()


## Pushes the loadout into the run stats.
func apply() -> void:
	GameState.set_meta_effects(Loadout.effects(CATALOG, state()) + _power_effects)


func _spend(amount: int) -> void:
	_add_credits(-amount)
	_changed()


## True when the previewed loadout only filled an empty mount (never swaps out a fitted part).
func _fills_empty(fitted: Dictionary, def: PartDef) -> bool:
	var mount := Loadout.mount_of(fitted, def.id)
	return mount != &"" and String(state()["mounts"].get(String(mount), "")) == ""


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


func _on_run_started(_difficulty: StringName) -> void:
	run_earned = 0
	_power_effects = []
	_paid.clear()
	apply()


func _on_run_ended(_victory: bool) -> void:
	HangarStock.roll(CATALOG, state(), _rng)
	SaveManager.save()


func _on_stage_started(stage_id: StringName) -> void:
	var path := "res://data/stages/%s.tres" % stage_id
	var stage: StageDef = load(path) if ResourceLoader.exists(path) else null
	_tracker = MedalTracker.new(stage.medal if stage else null)


func _on_stage_cleared(stage_id: StringName) -> void:
	var cleared: Array = state()["cleared"]
	if not String(stage_id) in cleared:
		cleared.append(String(stage_id))
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
