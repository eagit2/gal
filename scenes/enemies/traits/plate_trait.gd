class_name PlateTrait
extends EnemyTrait
## Bolts an armor plate onto the enemy's front that soaks shots until it breaks. Counter: hit it
## from the side as it turns mid-dive, or break the plate first.

@export var plate_scene: PackedScene


func begin(enemy: Enemy) -> void:
	enemy.add_child(plate_scene.instantiate())
