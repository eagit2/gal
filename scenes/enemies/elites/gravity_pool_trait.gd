class_name GravityPoolTrait
extends EliteTrait
## Lobs gravity pools at you that drag your ship and your shots into the well, like the player's
## Gravity Gun. Counter: steer clear of the pools and fire around them; shots near a pool bend in.

@export var pool_scene: PackedScene = preload("res://scenes/enemies/elites/gravity_pool.tscn")
@export var interval := 3.0
@export var pools := 1
@export var pool_speed := 120.0
@export var pool_life := 4.0
@export var radius := 110.0
@export var ship_pull := 140.0
@export var shot_pull := 420.0


func begin(elite: Elite) -> void:
	state(elite)["t"] = interval * 0.5
	state(elite)["pools"] = []


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered or not is_instance_valid(elite.target) or not elite.target.alive:
		return
	var t: float = state(elite)["t"] - delta
	if t <= 0.0:
		t = interval
		_lob(elite)
	state(elite)["t"] = t


func end(elite: Elite) -> void:
	for pool: Variant in state(elite).get("pools", []):
		if is_instance_valid(pool):
			(pool as Node).queue_free()
	state(elite)["pools"] = []


func _lob(elite: Elite) -> void:
	var list: Array = state(elite)["pools"]
	list = list.filter(is_instance_valid)
	for i in pools:
		var pool: GravityPool = pool_scene.instantiate()
		var aim := elite.target.global_position + Vector2((i - (pools - 1) / 2.0) * radius * 1.4, 0.0)
		pool.setup(elite.target, aim, pool_speed, pool_life, radius, ship_pull, shot_pull)
		pool.position = elite.global_position
		elite.entities.add_child(pool)
		list.append(pool)
	state(elite)["pools"] = list
