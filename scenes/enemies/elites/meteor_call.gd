class_name MeteorCallTrait
extends EliteTrait
## Every `interval` it marks `lanes` columns with warning stripes, then rains meteors down them.
## Meteors cost a life on contact and crush any enemy in the lane. Counter: stand outside the
## lanes, and lure enemies into them.

@export var meteor_scene: PackedScene
@export var warning_visual: PackedScene
@export var interval := 7.0
@export var warn_time := 1.4
@export var lanes := 2
@export var lane_width := 70.0
@export var meteors_per_lane := 4
@export var meteor_speed := 460.0


func begin(elite: Elite) -> void:
	elite.state["t"] = interval - 2.0
	elite.state["lanes"] = [] as Array[float]
	var warning: Node2D = warning_visual.instantiate()
	elite.entities.add_child.call_deferred(warning)
	elite.state["warning"] = warning


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var t: float = elite.state["t"] + delta
	var lane_xs: Array[float] = elite.state["lanes"]
	var warning: Node2D = elite.state["warning"]
	if lane_xs.is_empty() and t >= interval:
		lane_xs.assign(_pick_lanes(elite))
		t = 0.0
	elif not lane_xs.is_empty() and t >= warn_time:
		for x in lane_xs:
			for i in meteors_per_lane:
				_drop(elite, Vector2(x + randf_range(-lane_width, lane_width) * 0.35, -40.0 - i * 110.0))
		lane_xs.clear()
		t = 0.0
	warning.call("set_lanes", lane_xs, lane_width, t / warn_time if not lane_xs.is_empty() else 0.0)
	elite.state["t"] = t


func end(elite: Elite) -> void:
	var warning: Variant = elite.state.get("warning")
	if is_instance_valid(warning):
		(warning as Node).queue_free()


func _pick_lanes(elite: Elite) -> Array[float]:
	var picked: Array[float] = []
	# One lane on the player's column, the rest elsewhere.
	if is_instance_valid(elite.target):
		picked.append(clampf(elite.target.global_position.x, lane_width, 540.0 - lane_width))
	while picked.size() < lanes:
		var x := randf_range(lane_width, 540.0 - lane_width)
		if picked.all(func(p: float) -> bool: return absf(p - x) > lane_width * 1.6):
			picked.append(x)
	return picked


func _drop(elite: Elite, at: Vector2) -> void:
	var meteor: Node2D = meteor_scene.instantiate()
	meteor.position = at
	meteor.set("velocity", Vector2(randf_range(-15.0, 15.0), meteor_speed))
	meteor.set("source", elite)
	elite.entities.add_child(meteor)
