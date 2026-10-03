class_name HangarTree
extends Resource
## Every hangar node, in display order. Registered here because web builds can't list folders
## (a test checks nothing in data/hangar is missing).

@export var nodes: Array[HangarNodeDef] = []


func find(id: StringName) -> HangarNodeDef:
	for node in nodes:
		if node.id == id:
			return node
	return null
