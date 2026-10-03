class_name ModuleDef
extends Resource
## A hangar module (materia-style): slotted into a frame, earns AP from kills while equipped and
## levels up. At max level it is mastered: it spawns a fresh level-1 copy and can unlock chain
## modules in the shop. Visual: `part` sprite drawn at its slot on the ship.

enum Kind {
	WEAPON,  ## green: firepower
	SUPPORT,  ## blue: only works when linked to a module in a paired slot
	SYSTEM,  ## yellow: pickups, score, combos
	HULL,  ## purple: speed and shield
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: Kind
@export var cost: int = 100
## Effects at level 1 ({"stat", "op", "value"}, as in UpgradeDef).
@export var effects: Array[Dictionary] = []
## Effects added once for every level above 1.
@export var per_level: Array[Dictionary] = []
## Total AP needed to reach level 2, 3, ...; max level is size + 1.
@export var ap_levels: Array[int] = [60, 200]
## Support only: levels this module adds to the linked module.
@export var amplify: int = 0
## Support only: the linked module must be this kind for the effects to work; -1 means any kind.
@export var link_kind: int = -1
## Shop lists this module only after the named module has been mastered (upgrade chain).
@export var requires_mastered: StringName = &""
## Ship part sprite (assets/art/dusk_armada/parts/<part>.png), e.g. cannon_weapon.
@export var part: StringName = &"pod"


func max_level() -> int:
	return ap_levels.size() + 1


func level_for(ap: int) -> int:
	var level := 1
	for threshold in ap_levels:
		if ap >= threshold:
			level += 1
	return level
