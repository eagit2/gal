class_name BladeReleaseTrait
extends EliteTrait
## Every time it loses a third of its hp it releases blade divers that slash at you one after
## another. Counter: keep moving after each lock flash; the divers have 5 hp each.

@export var hp_step := 0.33
@export var count := 3
@export var diver: EnemyDef
@export var delay := 1.0
@export var slash_gap := 0.35


## How many hp thresholds (1 - step * k, k = 1, 2, ...) a hp fraction has passed beyond the
## `released` ones already used; the last threshold is kept above zero.
static func thresholds_passed(fraction: float, step: float, released: int) -> int:
	var passed := released
	while step > 0.0 and 1.0 - step * (passed + 1) > 0.0 and fraction <= 1.0 - step * (passed + 1) + 0.0001:
		passed += 1
	return passed - released


func begin(elite: Elite) -> void:
	state(elite)["released"] = 0
	elite.health.damaged.connect(_on_damaged.bind(elite))


func end(elite: Elite) -> void:
	if elite.health.damaged.is_connected(_on_damaged.bind(elite)):
		elite.health.damaged.disconnect(_on_damaged.bind(elite))


func _on_damaged(_amount: int, elite: Elite) -> void:
	if elite.health.hp <= 0 or not is_instance_valid(elite.target):
		return
	var due := thresholds_passed(float(elite.health.hp) / elite.health.max_hp, hp_step, state(elite)["released"])
	if due <= 0:
		return
	state(elite)["released"] += due
	# Deferred: hits land inside physics callbacks, where enemies can't be added.
	for n in due:
		_release.call_deferred(elite)


func _release(elite: Elite) -> void:
	if not is_instance_valid(elite) or elite.health.hp <= 0:
		return
	var def: EnemyDef = diver if diver != null else Roster.enemy(&"blade_diver")
	if def == null:
		return
	for i in count:
		var at := elite.position + Vector2((i - (count - 1) / 2.0) * 30.0, 30.0)
		var enemy := EnemySpawner.launch_at(def, elite.difficulty, at, elite.target, elite.entities)
		enemy.set_meta(&"slash_delay", delay + i * slash_gap)
