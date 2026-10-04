class_name SlotJamTrait
extends EnemyTrait
## While diving it locks a static beam on you; if it connects, one random weapon slot goes offline
## for a while. Counter: step out of the beam's line while it charges.

@export var beam_scene: PackedScene = preload("res://assets/art/dusk_armada/enemies/jam_beam.tscn")
@export var interval := 6.0
@export var charge_time := 1.0
@export var beam_width := 28.0
@export var jam_time := 5.0

const BEAM_LENGTH := 1400.0


## Whether `point` is inside a beam of `width` starting at `origin` and running along `direction`.
static func beam_hits(origin: Vector2, direction: Vector2, point: Vector2, width: float) -> bool:
	var nearest := Geometry2D.get_closest_point_to_segment(point, origin, origin + direction.normalized() * BEAM_LENGTH)
	return nearest.distance_to(point) <= width * 0.5


func tick(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	if enemy.state != Enemy.State.DIVING or not is_instance_valid(enemy.target) or not enemy.target.alive:
		_clear(enemy)
		s["t"] = 0.0
		return
	if not s.has("beam"):
		s["t"] = s.get("t", 0.0) + delta
		if s["t"] >= interval:
			_lock(enemy)
		return
	s["c"] += delta
	var beam: Node2D = s["beam"]
	beam.call("set_charge", s["c"] / charge_time)
	if s["c"] >= charge_time:
		_fire(enemy)


func killed(enemy: Enemy) -> void:
	_clear(enemy)


func _lock(enemy: Enemy) -> void:
	var s := state(enemy)
	var direction := enemy.global_position.direction_to(enemy.target.global_position)
	var beam: Node2D = beam_scene.instantiate()
	beam.top_level = true
	enemy.add_child(beam)
	beam.global_position = enemy.global_position
	beam.call("aim", direction, beam_width)
	s["beam"] = beam
	s["dir"] = direction
	s["origin"] = enemy.global_position
	s["c"] = 0.0
	s["t"] = 0.0


func _fire(enemy: Enemy) -> void:
	var s := state(enemy)
	var beam: Node2D = s["beam"]
	beam.call("fire")
	s.erase("beam")
	var player := enemy.target
	if beam_hits(s["origin"], s["dir"], player.global_position, beam_width):
		if player.jam_random_slot(jam_time) != &"":
			player.modulate = Color(2.0, 0.5, 1.8)
			player.create_tween().tween_property(player, "modulate", Color.WHITE, 0.6)


func _clear(enemy: Enemy) -> void:
	var s := state(enemy)
	if s.has("beam"):
		var beam: Node2D = s["beam"]
		if is_instance_valid(beam):
			beam.queue_free()
		s.erase("beam")
