class_name DevUnlock
extends RefCounted
## Development mode (on unless the URL or args say unlock=0): every ship, part, pilot and chip is
## owned, and ship tree nodes switch on and off for free. Pure functions on the loadout state.

## Copies of each chip granted, enough to fill every socket on the ship.
const CHIP_COPIES := 8


## Owns everything in the catalog (adds to the state; never removes).
static func grant_all(catalog: HangarCatalog, state: Dictionary) -> void:
	for def in catalog.parts:
		if not def.unique and not state["parts"].has(String(def.id)):
			state["parts"][String(def.id)] = {}
	var pilots: Array = state["pilots"]
	for def in catalog.pilots:
		if not String(def.id) in pilots:
			pilots.append(String(def.id))
	var cleared: Array = state["cleared"]
	for def in catalog.ships:
		if def.unlock_stage != &"" and not String(def.unlock_stage) in cleared:
			cleared.append(String(def.unlock_stage))
	for def in catalog.chips:
		state["chips"][String(def.id)] = maxi(int(state["chips"].get(String(def.id), 0)), CHIP_COPIES)


## Steps a node's rank up by one, or back to 0 from max. Switching on closes its fork partner;
## switching off also clears the nodes that hang from it. Parents are not required.
static func toggle(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> void:
	var ranks := ShipTree.ranks(state, ship)
	var rank := ShipTree.rank(state, ship, node)
	if rank >= node.max_rank:
		_clear(ranks, ship, node.id)
		return
	ranks[String(node.id)] = rank + 1
	if node.excludes != &"":
		_clear(ranks, ship, node.excludes)


static func _clear(ranks: Dictionary, ship: ShipDef, id: StringName) -> void:
	if not ranks.has(String(id)):
		return
	ranks.erase(String(id))
	for child in ship.tree:
		if id in child.requires:
			_clear(ranks, ship, child.id)
