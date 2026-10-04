class_name PuppeteerTrait
extends EliteTrait
## Every `interval` it hooks strings onto up to `puppets` formation enemies, then hurls them at the
## player in a fast staggered volley. Counter: kill it and every puppet still diving breaks off;
## the strings show which enemies are coming; Cryo Pulse holds the volley.

@export var puppets := 6
@export var interval := 6.0
@export var mark_time := 1.0
@export var stagger := 0.15
@export var puppet_brain: EnemyBrain = preload("res://data/brains/puppet.tres")
@export var strings_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/puppet_strings.tscn")


func begin(elite: Elite) -> void:
	state(elite)["timer"] = 3.0
	state(elite)["marked"] = [] as Array[Enemy]
	state(elite)["launched"] = [] as Array[Enemy]
	var strings: Node2D = strings_visual.instantiate()
	elite.add_child(strings)
	state(elite)["strings"] = strings


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var marked: Array[Enemy] = state(elite)["marked"]
	state(elite)["timer"] -= delta
	if marked.is_empty() and state(elite)["timer"] <= 0.0:
		marked.assign(_pick(elite))
		state(elite)["timer"] = mark_time
	elif not marked.is_empty() and state(elite)["timer"] <= 0.0:
		var next: Variant = marked.pop_front()
		if is_instance_valid(next) and (next as Enemy).state == Enemy.State.IN_FORMATION:
			(next as Enemy).start_attack(elite.target, 1.6, puppet_brain)
			state(elite)["launched"].append(next)
		state(elite)["timer"] = stagger if not marked.is_empty() else interval
	var launched: Array[Enemy] = state(elite)["launched"]
	launched.assign(launched.filter(func(e: Variant) -> bool: return is_instance_valid(e) and (e as Enemy).state == Enemy.State.DIVING))
	var points: Array[Vector2] = []
	for enemy: Variant in marked + launched:
		if is_instance_valid(enemy):
			points.append((enemy as Enemy).global_position)
	(state(elite)["strings"] as Node).call("set_targets", points)


func end(elite: Elite) -> void:
	for enemy: Variant in state(elite)["launched"]:
		if is_instance_valid(enemy):
			(enemy as Enemy).recall()


func _pick(elite: Elite) -> Array[Enemy]:
	var idle: Array[Enemy] = []
	for node in elite.get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.state == Enemy.State.IN_FORMATION:
			idle.append(enemy)
	idle.shuffle()
	return idle.slice(0, puppets)
