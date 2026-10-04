class_name FlagshipTrait
extends EnemyTrait
## Dives with an escort squad, Galaxian style. Kill the escorts first, then the flagship, for a
## big score and scrap bonus. Counter: pick off the escorts mid-dive.

@export var escort_enemy: EnemyDef = preload("res://data/enemies/bee.tres")
@export var escorts := 2
@export var bonus_mult := 3

const RECRUIT_RADIUS := 320.0
const HUNTER := preload("res://data/brains/hunter.tres")
const SIDE_GAP := 46.0
const BEHIND := -34.0


## Squad slot beside and behind the leader: alternating left and right, then further out.
static func escort_offset(index: int) -> Vector2:
	var side := -1.0 if index % 2 == 0 else 1.0
	return Vector2(side * SIDE_GAP * (1 + index / 2), BEHIND * (1 + index / 2))


## The bonus applies only when the flagship led escorts and every one of them is gone.
static func earns_bonus(led: int, alive: int) -> bool:
	return led > 0 and alive == 0


func tick(enemy: Enemy, _delta: float) -> void:
	var s := state(enemy)
	if enemy.state != Enemy.State.DIVING:
		s["dived"] = false
		return
	if s.get("dived", false):
		return
	s["dived"] = true
	# The escort brain is for followers; a leader flies the dive itself.
	if enemy.brain is EscortBrain:
		enemy.brain = HUNTER
		enemy.brain.begin(enemy)
	var squad: Array[Enemy] = []
	for recruit in enemy.nearby_idle(RECRUIT_RADIUS, escorts):
		recruit.start_escort(enemy, escort_offset(squad.size()))
		squad.append(recruit)
	while squad.size() < escorts:
		var extra := EnemySpawner.launch_at(escort_enemy, enemy.difficulty, enemy.position + Vector2(0, -30), enemy.target, enemy.entities, enemy.aggression)
		extra.leader = enemy
		extra.escort_offset = escort_offset(squad.size())
		extra.brain = Enemy.ESCORT_BRAIN
		extra.brain.begin(extra)
		squad.append(extra)
	s["squad"] = squad


func killed(enemy: Enemy) -> void:
	var squad: Array = state(enemy).get("squad", [])
	var alive := 0
	for e: Variant in squad:
		if is_instance_valid(e) and not (e as Enemy).is_queued_for_deletion():
			alive += 1
	if not earns_bonus(squad.size(), alive):
		return
	var extra := bonus_mult - 1
	GameState.add_score(extra * enemy.def.dive_score)
	EventBus.scrap_dropped.emit(enemy.global_position, extra * enemy.def.scrap)
