class_name PartDef
extends Resource
## A hangar part bought with scrap and fitted to a ship slot. Ranks 1-3 are bought one at a time;
## each effect applies from its "rank" key (default 1). Visual: the `part` sprite drawn at the mount
## it sits on, bigger and brighter at higher ranks.

enum Category { WEAPON, SHIELD, POWER, ENGINE, EXTRA, CHIP }
enum Tier { STARTER, COMMON, UNCOMMON, RARE, EPIC }

const MAX_RANK := 3
## Scrap to buy rank 1 of each tier; rank 2 costs the same again and rank 3 twice that.
const TIER_COST: Array[int] = [60, 100, 200, 400, 800]
## Slot each category fills on a ship. Engines, extras and chips share the Bonus slot.
const SLOT_OF: Array[StringName] = [&"weapon", &"shield", &"power", &"bonus", &"bonus", &"bonus"]

@export var id: StringName
@export var display_name: String
@export var category: Category
@export var tier: Tier
## What each rank adds, shown in the store: [rank 1, rank 2, rank 3].
@export var rank_text: Array[String] = ["", "", ""]
## {"stat", "op", "value", "rank"?}: as in UpgradeSystem, applied once the part reaches "rank".
@export var effects: Array[Dictionary] = []
## Ship part sprite (assets/art/dusk_armada/parts/<part>.png), e.g. cannon_weapon.
@export var part: StringName = &"pod_weapon"


func slot() -> StringName:
	return SLOT_OF[category]


func effects_at(rank: int) -> Array[Dictionary]:
	return effects.filter(func(e: Dictionary) -> bool: return int(e.get("rank", 1)) <= rank)


## Scrap to reach `rank` from the rank below it. Starter parts are free at rank 1.
func price(rank: int) -> int:
	if rank == 1:
		return 0 if tier == Tier.STARTER else TIER_COST[tier]
	return TIER_COST[tier] * (rank - 1)
