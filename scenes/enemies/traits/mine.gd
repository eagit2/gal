class_name Mine
extends Node2D
## A drifting mine. Costs a life on contact. Shot, it blows up and damages enemies, elites and other
## mines within BLAST_RADIUS, so it can set off chains.

const DRIFT := 45.0
const LIFETIME := 9.0
const BLAST_RADIUS := 90.0
const ENEMY_DAMAGE := 3
const ELITE_DAMAGE := 4
const BOTTOM := 1000.0

var _t := 0.0
var _x := 0.0
var _exploded := false


func _ready() -> void:
	add_to_group(&"mines")
	_x = position.x
	$Health.died.connect(explode)
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: queue_free())


func _physics_process(delta: float) -> void:
	if _exploded or GameState.freeze_left > 0.0:
		return
	_t += delta
	position.y += DRIFT * delta
	position.x = _x + sin(_t * 1.3) * 10.0
	if _t > LIFETIME or position.y > BOTTOM:
		queue_free()


func explode() -> void:
	if _exploded:
		return
	_exploded = true
	remove_from_group(&"mines")
	$Hurtbox.set_deferred(&"monitorable", false)
	$ContactHitbox.set_deferred(&"monitoring", false)
	$Visual.call("burst", BLAST_RADIUS)
	EventBus.elite_trait_broken.emit(global_position)
	_blast.call_deferred()
	get_tree().create_timer(0.35, false).timeout.connect(queue_free)


func _blast() -> void:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if (node as Node2D).global_position.distance_to(global_position) <= BLAST_RADIUS:
			(node as Enemy).damage(ENEMY_DAMAGE)
	for node in get_tree().get_nodes_in_group(&"elites"):
		if (node as Node2D).global_position.distance_to(global_position) <= BLAST_RADIUS:
			(node as Elite).damage(ELITE_DAMAGE)
	for node in get_tree().get_nodes_in_group(&"mines"):
		if (node as Node2D).global_position.distance_to(global_position) <= BLAST_RADIUS:
			(node as Mine).explode()
