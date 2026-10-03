class_name LinkComboDef
extends Resource
## A named combo: two chips in a linked pair of sockets on a fitted part. Its effects apply on top of
## the chips' own. Shown in the hangar only once it is active.

@export var id: StringName
@export var display_name: String
@export var text: String
## The two chip ids, in any order.
@export var chips: Array[StringName] = []
@export var effects: Array[Dictionary] = []


func matches(a: StringName, b: StringName) -> bool:
	return chips.size() == 2 and ((chips[0] == a and chips[1] == b) or (chips[0] == b and chips[1] == a))
