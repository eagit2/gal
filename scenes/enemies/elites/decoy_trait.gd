class_name DecoyTrait
extends EliteTrait
## Spawns hologram copies that mirror its moves and fire real fans. Only the real one casts a
## shadow. Counter: find the shadow; holograms pop in one hit.

@export var copy_scene: PackedScene = preload("res://scenes/enemies/elites/decoy_copy.tscn")
@export var shadow_visual: PackedScene = preload("res://assets/art/dusk_armada/elites/decoy_shadow.tscn")
@export var copies := 2
@export var interval := 8.0
@export var copy_life := 6.0


func begin(elite: Elite) -> void:
	state(elite)["t"] = interval * 0.4
	state(elite)["copies"] = []
	var shadow: Node2D = shadow_visual.instantiate()
	elite.add_child(shadow)
	state(elite)["shadow"] = shadow


func tick(elite: Elite, delta: float) -> void:
	if not elite.entered:
		return
	var t: float = state(elite)["t"] - delta
	if t <= 0.0:
		t = interval
		_summon(elite)
	state(elite)["t"] = t


func end(elite: Elite) -> void:
	for copy: Variant in state(elite).get("copies", []):
		if is_instance_valid(copy):
			(copy as Node).queue_free()
	state(elite)["copies"] = []


func _summon(elite: Elite) -> void:
	end(elite)
	var list: Array = []
	for i in copies:
		var copy: DecoyCopy = copy_scene.instantiate()
		copy.setup(elite, i, copy_life)
		elite.entities.add_child(copy)
		list.append(copy)
	state(elite)["copies"] = list
