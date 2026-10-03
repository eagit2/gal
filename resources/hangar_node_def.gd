class_name HangarNodeDef
extends Resource
## One permanent upgrade bought in the hangar with credits. Each rank applies `effects` once more,
## in the UpgradeDef effect format, under every run's upgrades (GameState.set_meta_effects).

enum Branch { HULL, WEAPONS, SYSTEMS }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var branch: Branch
## Credits for each rank; its size is the max rank.
@export var costs: Array[int] = []
## Each effect: {"stat": StringName, "op": "add"|"mul"|"max", "value": Variant}, applied once per rank.
@export var effects: Array[Dictionary] = []
## Node ids that need at least one rank before this one can be bought.
@export var requires: Array[StringName] = []


func max_rank() -> int:
	return costs.size()
