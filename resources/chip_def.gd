class_name ChipDef
extends Resource
## A chip for a part's link socket. Its effects apply while the part is fitted; two chips in a
## linked pair of sockets can form a combo (LinkComboDef). Bought from the store; owning N copies
## lets N sockets hold it.

@export var id: StringName
@export var display_name: String
## What it does, in one line.
@export var text: String
@export var color: Color = Color.WHITE
@export var price := 150
## {"stat", "op", "value"}, as in UpgradeSystem.
@export var effects: Array[Dictionary] = []
