class_name UpgradeDef
extends Resource

enum Rarity { COMMON, RARE, EPIC }
enum Category { PRIMARY, SECONDARY, DEFENSE, UTILITY }
## Both come from in-level pickups. UTILITY: rarer gold capsules (shield, freeze, credits, combos).
## BULLET: regular capsules (bullet characteristics only).
enum Source { UTILITY, BULLET }

const RARITY_COLORS: Array[Color] = [Color(0.957, 0.89, 0.757), Color(0.4, 0.85, 1.0), Color(1.0, 0.55, 0.95)]

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: Category
@export var rarity: Rarity = Rarity.COMMON
@export var source: Source = Source.UTILITY
@export var tags: Array[StringName] = []
@export var max_stacks: int = 1
## Each effect: {"stat": StringName, "op": "add"|"mul"|"flag", "value": Variant}
@export var effects: Array[Dictionary] = []
@export var requires: Array[StringName] = []
