class_name PlateTrait
extends EnemyTrait
## Bolts an armor plate onto the enemy's front that soaks shots until it breaks. Counter: hit it
## from the side as it turns mid-dive, or break the plate first.

@export var plate_scene: PackedScene = preload("res://scenes/enemies/traits/armor_plate.tscn")
## Hits the plate takes before it breaks.
@export var hp := 4


func begin(enemy: Enemy) -> void:
	var plate: Node = plate_scene.instantiate()
	(plate.get_node("Health") as Health).max_hp = hp
	enemy.add_child(plate)
