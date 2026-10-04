class_name SpawnerPipeTrait
extends EnemyTrait
## A fixed pod that keeps releasing small drones until destroyed. Counter: destroy the pod, not
## the drones.

@export var interval := 2.5
@export var max_alive := 4
@export var spawn_enemy: EnemyDef = preload("res://data/enemies/fragment.tres")
@export var pod_hp := 12

## Seconds the pod glows before it releases a drone.
const GLOW := 0.5
const ENTRY_SPEED := 260.0


## Whether the pod may release another drone: only while fewer than `cap` are alive.
static func can_spawn(alive: int, cap: int) -> bool:
	return alive < cap


func begin(enemy: Enemy) -> void:
	enemy.health().reset(maxi(1, roundi(pod_hp * enemy.difficulty.enemy_hp * enemy.hp_scale)))
	var s := state(enemy)
	s["t"] = interval * 0.6
	s["drones"] = []


func tick(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	if enemy.state == Enemy.State.ENTERING and not _park(enemy, s, delta):
		return
	var drones: Array = s["drones"]
	drones = drones.filter(func(d: Variant) -> bool: return is_instance_valid(d) and (d as Enemy).is_inside_tree())
	s["drones"] = drones
	var t: float = s["t"] - delta
	if not can_spawn(drones.size(), max_alive):
		t = maxf(t, GLOW)  # Full: hold the next release until a drone falls.
	if t <= GLOW:
		var glow := 1.0 + 0.8 * (1.0 - maxf(t, 0.0) / GLOW) if can_spawn(drones.size(), max_alive) else 1.0
		enemy.modulate = Color(glow, glow, glow)
	if t <= 0.0:
		enemy.modulate = Color.WHITE
		_release(enemy, drones)
		t = interval
	s["t"] = t


## The pod has speed 0, so the entry path would never move it: slide it to its slot (or, with no
## slot, a firing spot near the top) ourselves. True once it sits there.
func _park(enemy: Enemy, s: Dictionary, delta: float) -> bool:
	if enemy.def.speed > 0.0:
		return false
	var slotted := enemy.slot != Enemy.NO_SLOT
	var goal := enemy.formation.slot_position(enemy.slot) if slotted else Vector2(clampf(enemy.position.x, 60.0, 480.0), 200.0)
	var at: Vector2 = s.get("entry_pos", enemy.position)  # The entry path resets position each frame.
	at = at.move_toward(goal, ENTRY_SPEED * delta)
	s["entry_pos"] = at
	enemy.position = at
	if at.distance_to(goal) > 1.0:
		return false
	if slotted:
		enemy.state = Enemy.State.IN_FORMATION
	s["parked"] = true
	return true


func killed(enemy: Enemy) -> void:
	state(enemy)["drones"] = []  # The drones fly on, no longer linked to the pod.


func _release(enemy: Enemy, drones: Array) -> void:
	if not is_instance_valid(enemy.target) or not is_instance_valid(enemy.entities):
		return
	var def := spawn_enemy if spawn_enemy else Roster.enemy(&"fragment")
	var drone := EnemySpawner.launch_at(def, enemy.difficulty, enemy.global_position + Vector2(0, 18), enemy.target, enemy.entities, 1.3)
	drones.append(drone)
