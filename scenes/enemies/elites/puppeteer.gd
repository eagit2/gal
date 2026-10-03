class_name PuppeteerTrait
extends EliteTrait
## Every `interval` it hooks strings onto up to `puppets` formation enemies, then hurls them at the
## player in a fast staggered volley. Counter: kill it and every puppet still diving breaks off;
## the strings show which enemies are coming; Cryo Pulse holds the volley.

@export var puppets := 6
@export var interval := 6.0
@export var mark_time := 1.0
@export var stagger := 0.15
@export var puppet_brain: EnemyBrain
@export var strings_visual: PackedScene


func begin(elite: Elite) -> void:
	elite.state["timer"] = 3.0
	elite.state["marked"] = [] as Array[Enemy]
	elite.state["launched"] = [] as Array[Enemy]
	var strings: Node2D = strings_visual.instantiate()
	elite.add_child(strings)
	elite.state["strings"] = strings


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var marked: Array[Enemy] = elite.state["marked"]
	elite.state["timer"] -= delta
	if marked.is_empty() and elite.state["timer"] <= 0.0:
		marked.assign(_pick(elite))
		elite.state["timer"] = mark_time
	elif not marked.is_empty() and elite.state["timer"] <= 0.0:
		var next: Variant = marked.pop_front()
		if is_instance_valid(next) and (next as Enemy).state == Enemy.State.IN_FORMATION:
			(next as Enemy).start_attack(elite.target, 1.6, puppet_brain)
			elite.state["launched"].append(next)
		elite.state["timer"] = stagger if not marked.is_empty() else interval
	var launched: Array[Enemy] = elite.state["launched"]
	launched.assign(launched.filter(func(e: Variant) -> bool: return is_instance_valid(e) and (e as Enemy).state == Enemy.State.DIVING))
	var points: Array[Vector2] = []
	for enemy: Variant in marked + launched:
		if is_instance_valid(enemy):
			points.append((enemy as Enemy).global_position)
	(elite.state["strings"] as Node).call("set_targets", points)


func end(elite: Elite) -> void:
	for enemy: Variant in elite.state["launched"]:
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
