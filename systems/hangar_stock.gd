class_name HangarStock
extends RefCounted
## The store's rotating stock: a few parts you don't own yet, rolled with rarer parts less often.
## Restocks after every run, or early for a reroll fee. Pure functions on the loadout state.

const SIZE := 5
const REROLL_COST := 40
## Roll weight by PartDef.Tier: starter, common, uncommon, rare, epic.
const WEIGHTS: Array[int] = [6, 6, 4, 2, 1]


## Replaces state["stock"] with up to SIZE different unowned parts.
static func roll(catalog: HangarCatalog, state: Dictionary, rng: RandomNumberGenerator) -> void:
	var pool: Array[PartDef] = catalog.parts.filter(func(p: PartDef) -> bool: return not Loadout.owns(state, p.id))
	var stock: Array = []
	while stock.size() < SIZE and not pool.is_empty():
		var total := 0
		for p in pool:
			total += WEIGHTS[p.tier]
		var pick := rng.randi_range(1, total)
		for p in pool:
			pick -= WEIGHTS[p.tier]
			if pick <= 0:
				stock.append(String(p.id))
				pool.erase(p)
				break
	state["stock"] = stock


static func in_stock(state: Dictionary, id: StringName) -> bool:
	return String(id) in (state["stock"] as Array)


## Buys a stocked part (the caller pays def.price()): owned at level 0 and gone from the stock.
static func take(state: Dictionary, def: PartDef) -> bool:
	if not in_stock(state, def.id) or Loadout.owns(state, def.id):
		return false
	(state["stock"] as Array).erase(String(def.id))
	state["parts"][String(def.id)] = {}
	return true
