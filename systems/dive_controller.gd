class_name DiveController
extends Node
## Sends formation enemies to dive at the player. Rate scales with difficulty and stage aggression.

var active := false
var difficulty: DifficultyDef
var aggression := 1.0
var target: Player
var _timer := 1.5


func _physics_process(delta: float) -> void:
	if not active or not target.alive:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(1.0, 2.4) / (difficulty.dive_frequency * aggression)
	var ready: Array[Enemy] = []
	var diving := 0
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.state == Enemy.State.IN_FORMATION:
			ready.append(enemy)
		elif enemy.state == Enemy.State.DIVING:
			diving += 1
	if ready.is_empty() or diving >= max_divers():
		return
	ready.pick_random().start_dive(target.global_position)


func max_divers() -> int:
	return clampi(roundi(2.0 * aggression), 2, 6)
