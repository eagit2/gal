class_name RockTowTrait
extends EliteTrait
## Tows a giant space rock on a tether below it. The rock blocks shots from below and takes a huge
## number of hits, breaking off falling chunks (each a hazard worth scrap) as it wears down.
## Counter: shoot the thin tether from an angle to drop the rock (the elite then fires faster),
## or grind the rock down and dodge the chunks.

@export var rock_scene: PackedScene = preload("res://scenes/enemies/elites/towed_rock.tscn")
@export var rock_hp := 240
@export var chunks := 6
@export var tether_length := 150.0
## Fire interval multiplier once the tether is cut.
@export var enraged_fire := 0.55


func begin(elite: Elite) -> void:
	var rock: Node2D = rock_scene.instantiate()
	rock.call("setup", elite, maxi(chunks, roundi(rock_hp * elite.difficulty.enemy_hp)), chunks, tether_length)
	elite.entities.add_child.call_deferred(rock)
	state(elite)["rock"] = rock


func tick(elite: Elite, _delta: float) -> void:
	var rock: Variant = state(elite).get("rock")
	if not is_instance_valid(rock) or not rock.get("tethered"):
		elite.fire_scale = enraged_fire


func end(elite: Elite) -> void:
	var rock: Variant = state(elite).get("rock")
	if is_instance_valid(rock):
		rock.call("cut")
