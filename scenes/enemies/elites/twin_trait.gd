class_name TwinTrait
extends EliteTrait
## Comes as a linked pair. When one dies, the other rebuilds it after `revive_time` (up to
## `revives` times). Counter: kill both within the revive window; split your damage.

@export var link_visual: PackedScene
@export var revive_time := 3.0
@export var revives := 2

const ELITE_SCENE := "res://scenes/enemies/elite.tscn"


func begin(elite: Elite) -> void:
	elite.state["revive_left"] = -1.0
	var link: Node2D = link_visual.instantiate()
	elite.add_child(link)
	elite.state["link"] = link
	if not elite.state.has("partner"):
		elite.state["revives"] = revives
		_spawn_partner.call_deferred(elite, elite.position + Vector2(140.0 if elite.position.x < 270.0 else -140.0, 0), 1.0)


func tick(elite: Elite, delta: float) -> void:
	var partner: Variant = elite.state.get("partner")
	var points: Array[Vector2] = []
	if is_instance_valid(partner):
		points.append((partner as Elite).global_position)
	(elite.state["link"] as Node).call("set_targets", points)
	if elite.state["revive_left"] >= 0.0:
		elite.state["revive_left"] -= delta
		if elite.state["revive_left"] < 0.0:
			_spawn_partner(elite, elite.state["revive_at"], 0.6)


func end(elite: Elite) -> void:
	var partner: Variant = elite.state.get("partner")
	if is_instance_valid(partner) and (partner as Elite).state["revives"] > 0:
		(partner as Elite).state["revive_left"] = revive_time
		(partner as Elite).state["revive_at"] = elite.position


func _spawn_partner(elite: Elite, at: Vector2, hp_fraction: float) -> void:
	if not is_instance_valid(elite) or not elite.is_inside_tree():
		return
	var twin: Elite = load(ELITE_SCENE).instantiate()
	twin.setup(elite.def, elite.difficulty, elite.target, elite.entities)
	twin.hp_scale = elite.hp_scale * hp_fraction
	twin.state["partner"] = elite
	twin.state["revives"] = elite.state["revives"]
	if hp_fraction < 1.0:
		elite.state["revives"] -= 1
		twin.state["revives"] = elite.state["revives"]
		twin.position = at
		twin.entered = true
	else:
		twin.position = Vector2(clampf(at.x, Elite.MIN_X, Elite.MAX_X), -60.0)
	elite.state["partner"] = twin
	elite.entities.add_child(twin)
