class_name TwinTrait
extends EliteTrait
## Comes as a linked pair. When one dies, the other rebuilds it after `revive_time` (up to
## `revives` times). Counter: kill both within the revive window; split your damage.

@export var link_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/twin_link.tscn")
@export var revive_time := 3.0
@export var revives := 2

const ELITE_SCENE := "res://scenes/enemies/elite.tscn"


func begin(elite: Elite) -> void:
	state(elite)["revive_left"] = -1.0
	var link: Node2D = link_visual.instantiate()
	elite.add_child(link)
	state(elite)["link"] = link
	if not state(elite).has("partner"):
		state(elite)["revives"] = revives
		_spawn_partner.call_deferred(elite, elite.position + Vector2(140.0 if elite.position.x < 270.0 else -140.0, 0), 1.0)


func tick(elite: Elite, delta: float) -> void:
	var partner: Variant = state(elite).get("partner")
	var points: Array[Vector2] = []
	if is_instance_valid(partner):
		points.append((partner as Elite).global_position)
	(state(elite)["link"] as Node).call("set_targets", points)
	if state(elite)["revive_left"] >= 0.0:
		state(elite)["revive_left"] -= delta
		if state(elite)["revive_left"] < 0.0:
			_spawn_partner(elite, state(elite)["revive_at"], 0.6)


func end(elite: Elite) -> void:
	var partner: Variant = state(elite).get("partner")
	if is_instance_valid(partner) and state(partner as Elite)["revives"] > 0:
		state(partner as Elite)["revive_left"] = revive_time
		state(partner as Elite)["revive_at"] = elite.position


func _spawn_partner(elite: Elite, at: Vector2, hp_fraction: float) -> void:
	if not is_instance_valid(elite) or not elite.is_inside_tree():
		return
	var twin: Elite = load(ELITE_SCENE).instantiate()
	twin.setup(elite.def, elite.difficulty, elite.target, elite.entities)
	twin.hp_scale = elite.hp_scale * hp_fraction
	state(twin)["partner"] = elite
	state(twin)["revives"] = state(elite)["revives"]
	if hp_fraction < 1.0:
		state(elite)["revives"] -= 1
		state(twin)["revives"] = state(elite)["revives"]
		twin.position = at
		twin.entered = true
	else:
		twin.position = Vector2(clampf(at.x, Elite.MIN_X, Elite.MAX_X), -60.0)
	state(elite)["partner"] = twin
	elite.entities.add_child(twin)
