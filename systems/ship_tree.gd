class_name ShipTree
extends RefCounted
## Blueprint tree rules on the saved loadout state (state["tree"][ship id][node id] = rank). A node
## on a mount needs the part fitted there to be rare enough; owned ranks stay but go dark while it
## isn't. Pure functions so tests can call them directly.

enum Gate { OPEN, NEEDS_NODE, NEEDS_PART, MAXED }


static func ranks(state: Dictionary, ship: ShipDef) -> Dictionary:
	var tree: Dictionary = state["tree"]
	if not tree.has(String(ship.id)):
		tree[String(ship.id)] = {}
	return tree[String(ship.id)]


static func rank(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> int:
	return int(ranks(state, ship).get(String(node.id), 0))


## True when the node's mount holds a part of at least its rarity (hull nodes always are).
static func powered(catalog: HangarCatalog, state: Dictionary, node: TreeNodeDef) -> bool:
	if node.mount == &"hull":
		return true
	var part := Loadout.part_at(catalog, state, node.mount)
	return part != null and part.tier >= node.min_tier


## Whether the next rank can be bought, and if not, why.
static func gate(catalog: HangarCatalog, state: Dictionary, node: TreeNodeDef) -> Gate:
	var ship := Loadout.ship_of(catalog, state)
	if rank(state, ship, node) >= node.max_rank:
		return Gate.MAXED
	var parent := ship.node(node.requires) if node.requires != &"" else null
	if parent and rank(state, ship, parent) == 0:
		return Gate.NEEDS_NODE
	return Gate.OPEN if powered(catalog, state, node) else Gate.NEEDS_PART


static func price(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> int:
	return node.cost * (rank(state, ship, node) + 1)


## Adds a rank when the gate is open. The caller pays.
static func buy(catalog: HangarCatalog, state: Dictionary, node: TreeNodeDef) -> bool:
	if gate(catalog, state, node) != Gate.OPEN:
		return false
	var ship := Loadout.ship_of(catalog, state)
	ranks(state, ship)[String(node.id)] = rank(state, ship, node) + 1
	return true


## Effects of every owned, powered node on the current ship.
static func effects(catalog: HangarCatalog, state: Dictionary) -> Array[Dictionary]:
	var ship := Loadout.ship_of(catalog, state)
	var result: Array[Dictionary] = []
	for node in ship.tree:
		var r := rank(state, ship, node)
		if r > 0 and powered(catalog, state, node):
			result.append_array(PartDef.scaled(node.effects, r))
	return result
