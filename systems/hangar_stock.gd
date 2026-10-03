class_name HangarStock
extends RefCounted
## The store's rotating stock: a few parts you don't own yet (rarer parts less often) and chips.
## Restocks after every run, or early for a reroll fee. Pure functions on the loadout state.

const SIZE := 3
const REROLL_COST := 40
## Roll weight by PartDef.Tier: starter, common, uncommon, rare, epic.
const WEIGHTS: Array[int] = [6, 6, 4, 2, 1]
## Roll weight of each chip (chips can be bought again and again).
const CHIP_WEIGHT := 2


## Replaces state["stock"] with up to SIZE different picks: unowned parts and chips.
static func roll(catalog: HangarCatalog, state: Dictionary, rng: RandomNumberGenerator) -> void:
	var pool: Array[Resource] = []
	pool.append_array(catalog.parts.filter(func(p: PartDef) -> bool: return not Loadout.owns(state, p.id)))
	pool.append_array(catalog.chips)
	var stock: Array = []
	while stock.size() < SIZE and not pool.is_empty():
		var total := 0
		for r in pool:
			total += _weight(r)
		var pick := rng.randi_range(1, total)
		for r in pool:
			pick -= _weight(r)
			if pick <= 0:
				stock.append(String(r.id))
				pool.erase(r)
				break
	state["stock"] = stock


static func _weight(item: Resource) -> int:
	return WEIGHTS[item.tier] if item is PartDef else CHIP_WEIGHT


static func in_stock(state: Dictionary, id: StringName) -> bool:
	return String(id) in (state["stock"] as Array)


## Buys a stocked part (the caller pays def.price()): owned at level 0 and gone from the stock.
static func take(state: Dictionary, def: PartDef) -> bool:
	if not in_stock(state, def.id) or Loadout.owns(state, def.id):
		return false
	(state["stock"] as Array).erase(String(def.id))
	state["parts"][String(def.id)] = {}
	return true


## Buys a stocked chip (the caller pays its price): one more copy, gone from the stock.
static func take_chip(state: Dictionary, chip: ChipDef) -> bool:
	if not in_stock(state, chip.id):
		return false
	(state["stock"] as Array).erase(String(chip.id))
	state["chips"][String(chip.id)] = int(state["chips"].get(String(chip.id), 0)) + 1
	return true
