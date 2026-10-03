class_name UpgradePool
extends Resource
## Every upgrade and synergy that can appear in a run. Exported web builds can't list folders
## reliably, so content is registered here (a test checks nothing in data/upgrades is missing).

@export var upgrades: Array[UpgradeDef] = []
@export var synergies: Array[SynergyDef] = []
## Card and drop weights per rarity: common, rare, epic.
@export var rarity_weights: Array[float] = [70.0, 25.0, 5.0]


func find(id: StringName) -> UpgradeDef:
	for upgrade in upgrades:
		if upgrade.id == id:
			return upgrade
	return null
