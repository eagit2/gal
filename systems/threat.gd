class_name Threat
extends RefCounted
## Reads danger around the player so pilot powers and Cryo Pulse can fire on their own
## (controls are only steering and firing).

const GROUPS: Array[StringName] = [&"enemy_shots", &"enemies", &"elites"]


## Enemies and enemy shots within `radius` of `pos`.
static func count(tree: SceneTree, pos: Vector2, radius: float) -> int:
	var total := 0
	for group in GROUPS:
		for node in tree.get_nodes_in_group(group):
			if node is Node2D and (node as Node2D).global_position.distance_to(pos) <= radius:
				total += 1
	return total


## Direction from the closest threat within `radius` toward `pos`, or ZERO when none is close.
static func away(tree: SceneTree, pos: Vector2, radius: float) -> Vector2:
	var best := radius
	var from := Vector2.ZERO
	for group in GROUPS:
		for node in tree.get_nodes_in_group(group):
			if not node is Node2D:
				continue
			var d := (node as Node2D).global_position.distance_to(pos)
			if d < best:
				best = d
				from = (node as Node2D).global_position
	return Vector2.ZERO if from == Vector2.ZERO else (pos - from).normalized()


## Any enemy on screen at all.
static func any_enemy(tree: SceneTree) -> bool:
	return tree.get_first_node_in_group(&"enemies") != null or tree.get_first_node_in_group(&"elites") != null
