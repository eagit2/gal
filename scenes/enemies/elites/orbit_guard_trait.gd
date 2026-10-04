class_name OrbitGuardTrait
extends EliteTrait
## Drones orbit it and block shots, like Gradius options; destroyed drones respawn after a while.
## Counter: time shots through the gaps or pop drones, then burst the core.

@export var drone_scene: PackedScene = preload("res://scenes/enemies/elites/orbit_drone.tscn")
@export var drones := 4
@export var drone_hp := 3
@export var orbit_radius := 70.0
@export var spin := 2.0
@export var respawn := 5.0


## Where drone `index` of `total` sits on the ring at spin angle `angle`.
static func slot_position(index: int, total: int, angle: float, radius: float) -> Vector2:
	return Vector2.from_angle(angle + TAU * index / maxi(1, total)) * radius


func begin(elite: Elite) -> void:
	state(elite)["angle"] = 0.0
	state(elite)["drones"] = []
	state(elite)["waits"] = []
	for i in drones:
		state(elite)["drones"].append(null)
		state(elite)["waits"].append(-1.0)
		_spawn(elite, i)


func tick(elite: Elite, delta: float) -> void:
	var angle: float = state(elite)["angle"] + spin * delta
	state(elite)["angle"] = angle
	var list: Array = state(elite)["drones"]
	var waits: Array = state(elite)["waits"]
	for i in list.size():
		var drone: Variant = list[i]
		if is_instance_valid(drone) and not (drone as Node).is_queued_for_deletion():
			(drone as Node2D).position = slot_position(i, list.size(), angle, orbit_radius)
		elif waits[i] < 0.0:
			waits[i] = respawn
		else:
			waits[i] -= delta
			if waits[i] <= 0.0:
				_spawn(elite, i)
				waits[i] = -1.0


func end(elite: Elite) -> void:
	for drone: Variant in state(elite).get("drones", []):
		if is_instance_valid(drone):
			(drone as Node).queue_free()
	state(elite)["drones"] = []
	state(elite)["waits"] = []


func _spawn(elite: Elite, index: int) -> void:
	var drone: OrbitDrone = drone_scene.instantiate()
	drone.setup(maxi(1, roundi(drone_hp * elite.difficulty.enemy_hp)))
	drone.position = slot_position(index, drones, state(elite)["angle"], orbit_radius)
	elite.add_child(drone)
	state(elite)["drones"][index] = drone
