extends Node
## Object pools for frequently spawned scenes (bullets, particles, pickups).

var _pools: Dictionary = {}  # PackedScene -> Array[Node]


func acquire(scene: PackedScene) -> Node:
	var pool: Array = _pools.get(scene, [])
	if pool.is_empty():
		return scene.instantiate()
	return pool.pop_back()


func release(scene: PackedScene, node: Node) -> void:
	if node.get_parent():
		node.get_parent().remove_child(node)
	if not _pools.has(scene):
		_pools[scene] = []
	_pools[scene].append(node)
