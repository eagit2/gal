class_name UpgradeDef
extends Resource

enum Rarity { COMMON, RARE, EPIC }
enum Category { PRIMARY, SECONDARY, DEFENSE, UTILITY }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: Category
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []
@export var max_stacks: int = 1
## Each effect: {"stat": StringName, "op": "add"|"mul"|"flag", "value": Variant}
@export var effects: Array[Dictionary] = []
@export var requires: Array[StringName] = []
