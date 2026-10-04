class_name ShieldLinkTrait
extends EliteTrait
## Projects shield beams onto the nearest formation enemies, making them immune to shots. The
## elite itself is not shielded. Counter: kill the elite first; enemies that dive out of range
## lose their shield.

@export var links := 5
@export var radius := 300.0
@export var refresh := 0.4
@export var beam_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/shield_beams.tscn")


func begin(elite: Elite) -> void:
	state(elite)["linked"] = [] as Array[Enemy]
	state(elite)["refresh"] = 0.0
	var beams: Node2D = beam_visual.instantiate()
	elite.add_child(beams)
	state(elite)["beams"] = beams


func tick(elite: Elite, delta: float) -> void:
	state(elite)["refresh"] -= delta
	if state(elite)["refresh"] <= 0.0 and elite.entered:
		state(elite)["refresh"] = refresh
		_relink(elite)
	var points: Array[Vector2] = []
	for enemy: Variant in state(elite)["linked"]:
		if is_instance_valid(enemy):
			points.append((enemy as Enemy).global_position)
	(state(elite)["beams"] as Node).call("set_targets", points)


func end(elite: Elite) -> void:
	for enemy: Variant in state(elite)["linked"]:
		if is_instance_valid(enemy):
			(enemy as Enemy).set_shielded(false)
	state(elite)["linked"] = [] as Array[Enemy]


func _relink(elite: Elite) -> void:
	var candidates: Array[Enemy] = []
	for node in elite.get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and enemy.state != Enemy.State.DIVING and enemy.position.distance_to(elite.position) <= radius:
			candidates.append(enemy)
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.position.distance_squared_to(elite.position) < b.position.distance_squared_to(elite.position))
	var keep := candidates.slice(0, links)
	for enemy: Variant in state(elite)["linked"]:
		if is_instance_valid(enemy) and enemy not in keep:
			(enemy as Enemy).set_shielded(false)
	for enemy in keep:
		enemy.set_shielded(true)
	state(elite)["linked"] = keep
