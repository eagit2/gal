class_name DiveController
extends Node
## Sends formation enemies out to attack in squads and makes the formation fire. Each attacker's
## brain decides how it attacks. Pressure scales with difficulty and stage aggression.

var active := false
var difficulty: DifficultyDef
var aggression := 1.0
## Dive speed multiplier for kamikaze (swarmer) brains.
var kamikaze_speed := 1.0
var target: Player
var _timer := 0.8
var _volley := 1.5


func _physics_process(delta: float) -> void:
	if not active or not target.alive or GameState.freeze_left > 0.0:
		return
	_timer -= delta
	_volley -= delta
	if _timer <= 0.0:
		_timer = randf_range(0.45, 1.1) / (difficulty.dive_frequency * aggression)
		_launch_squad()
	if _volley <= 0.0:
		_volley = randf_range(0.7, 1.5) / (difficulty.formation_fire * aggression)
		_formation_shot()


func _launch_squad() -> void:
	var idle := _idle()
	var room := max_attackers() - get_tree().get_nodes_in_group(&"attackers").size()
	if idle.is_empty() or room <= 0:
		return
	idle.shuffle()
	for i in mini(mini(room, idle.size()), randi_range(1, 3)):
		idle[i].kamikaze_speed = kamikaze_speed
		idle[i].start_attack(target, aggression)


func _formation_shot() -> void:
	var idle := _idle()
	if not idle.is_empty():
		var shooter: Enemy = idle.pick_random()
		shooter.fire_at(shooter.predicted_player(0.4), 4.0)


func _idle() -> Array[Enemy]:
	var idle: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.state == Enemy.State.IN_FORMATION:
			idle.append(enemy)
	return idle


func max_attackers() -> int:
	return max_attackers_for(difficulty.dive_frequency, aggression)


static func max_attackers_for(frequency: float, stage_aggression: float) -> int:
	return clampi(roundi(4.0 * frequency * stage_aggression), 3, 12)
