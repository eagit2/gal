class_name PartDef
extends Resource
## A hangar part bought with scrap (from the store's rotating stock) and fitted to a ship slot. Its
## base `effects` apply while fitted; each attribute (POWER, SPEED, ...) is upgraded level by level
## in the part's menu. Rarity (`tier`) also decides which ship tree nodes its mount opens.
## Visual: the `part` sprite drawn at its mount, brighter and doubled as attributes level up.

enum Category { WEAPON, SHIELD, POWER, ENGINE, EXTRA, CHIP }
enum Tier { STARTER, COMMON, UNCOMMON, RARE, EPIC }

## Scrap to buy a part of each tier.
const TIER_COST: Array[int] = [60, 100, 200, 400, 800]
## Scrap per attribute level by tier: level N costs N times this.
const LEVEL_COST: Array[int] = [30, 50, 80, 120, 180]
## Slot each category fills on a ship. Engines, extras and chips share the Bonus slot.
const SLOT_OF: Array[StringName] = [&"weapon", &"shield", &"power", &"bonus", &"bonus", &"bonus"]

@export var id: StringName
@export var display_name: String
@export var category: Category
@export var tier: Tier
## What the part does, in one line.
@export var text: String
## {"stat", "op", "value"}: as in UpgradeSystem, applied while fitted.
@export var effects: Array[Dictionary] = []
## Upgradable attributes: {"id", "name", "text", "max", "effects": [{"stat", "op", "value"}]}. Each
## level applies the effects once more (add: value x level, mul: value ^ level).
@export var attributes: Array[Dictionary] = []
## Ship part sprite (assets/art/dusk_armada/parts/<part>.png), e.g. cannon_weapon.
@export var part: StringName = &"pod_weapon"


func slot() -> StringName:
	return SLOT_OF[category]


func price() -> int:
	return TIER_COST[tier]


func attribute(attr_id: StringName) -> Dictionary:
	for a in attributes:
		if a["id"] == attr_id:
			return a
	return {}


## Scrap to raise an attribute to `level`.
func level_price(level: int) -> int:
	return LEVEL_COST[tier] * level


## Effects of the part with `levels` ({attribute id: level}).
func effects_at(levels: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = effects.duplicate()
	for a in attributes:
		var level := int(levels.get(String(a["id"]), 0))
		if level > 0:
			result.append_array(scaled(a["effects"], level))
	return result


## Effects applied `times` times over, as one effect each.
static func scaled(list: Array, times: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e: Dictionary in list:
		var value: float = e["value"]
		var total: Variant = pow(value, times) if e["op"] == &"mul" else (value * times if value is float else int(value) * times)
		result.append({"stat": e["stat"], "op": e["op"], "value": total})
	return result
