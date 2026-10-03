extends Node2D
## Secondary weapons from upgrades: homing missiles on a timer, and wing drones that fire a straight
## shot whenever the ship fires. Counts come from GameState.stats (missiles, missile_rate, drones).

const MISSILE_SCENE := preload("res://scenes/projectiles/missile.tscn")
const DRONE_VISUAL := preload("res://assets/art/dusk_armada/player.tscn")
const MISSILE_INTERVAL := 2.0
const MISSILE_SPEED := 520.0
const MISSILE_TURN := 5.0
const MISSILE_DAMAGE := 2
const DRONE_OFFSETS: Array[Vector2] = [Vector2(-46, 14), Vector2(46, 14), Vector2(-80, 30), Vector2(80, 30)]
const DRONE_SCALE := 0.5

var player: Player
var _missile_timer := MISSILE_INTERVAL
var _drones: Array[Node2D] = []


func _ready() -> void:
	EventBus.stats_changed.connect(_sync_drones)
	EventBus.shot_fired.connect(_on_shot_fired)
	_sync_drones()


func _physics_process(delta: float) -> void:
	var count: int = GameState.stats[&"missiles"]
	if count <= 0 or not player.alive:
		return
	_missile_timer -= delta / Engine.time_scale
	if _missile_timer > 0.0:
		return
	_missile_timer = MISSILE_INTERVAL / GameState.stats[&"missile_rate"]
	for degrees in WeaponDef.fan(count, 30.0 + 10.0 * count):
		var missile: Bullet = Pools.acquire(MISSILE_SCENE)
		var velocity := Vector2.UP.rotated(deg_to_rad(degrees)) * MISSILE_SPEED
		missile.launch(player.entities, global_position + Vector2(0, -10), velocity, MISSILE_DAMAGE, MISSILE_SCENE, 0, MISSILE_TURN)


func _sync_drones() -> void:
	var wanted := mini(int(GameState.stats[&"drones"]), DRONE_OFFSETS.size())
	while _drones.size() < wanted:
		var drone: Node2D = DRONE_VISUAL.instantiate()
		drone.scale = Vector2.ONE * DRONE_SCALE
		drone.position = DRONE_OFFSETS[_drones.size()]
		add_child(drone)
		_drones.append(drone)
	while _drones.size() > wanted:
		_drones.pop_back().queue_free()


func _on_shot_fired() -> void:
	for drone in _drones:
		player.fire_shot(drone.global_position + Vector2(0, -12), 0.0)
