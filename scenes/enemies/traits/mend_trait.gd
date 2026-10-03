class_name MendTrait
extends EnemyTrait
## Every `interval` it repairs damaged enemies (and elites) within `radius`, with a visible beam.
## Counter: it is fragile, so kill it first.

@export var radius := 140.0
@export var interval := 2.0
@export var amount := 1
@export var elite_amount := 3
@export var beam_visual: PackedScene

const BEAM_TIME := 0.5


func begin(enemy: Enemy) -> void:
	var beams: Node2D = beam_visual.instantiate()
	enemy.add_child(beams)
	enemy.trait_state["beams"] = beams
	enemy.trait_state["t"] = randf() * interval


func tick(enemy: Enemy, delta: float) -> void:
	var t: float = enemy.trait_state["t"] + delta
	var beams: Node2D = enemy.trait_state["beams"]
	if t >= BEAM_TIME and t - delta < BEAM_TIME:
		beams.call("set_targets", [] as Array[Vector2])
	if t >= interval:
		t = 0.0
		beams.call("set_targets", _mend(enemy))
	enemy.trait_state["t"] = t


func _mend(enemy: Enemy) -> Array[Vector2]:
	var mended: Array[Vector2] = []
	for node in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var other := node as Enemy
		if other != enemy and other.position.distance_to(enemy.position) <= radius and other.health().heal(amount):
			mended.append(other.global_position)
	for node in enemy.get_tree().get_nodes_in_group(&"elites"):
		var elite := node as Elite
		if elite.position.distance_to(enemy.position) <= radius and elite.health.heal(elite_amount):
			mended.append(elite.global_position)
	return mended
