class_name ShipTree
extends RefCounted
## Ship skill tree rules on the saved loadout state (state["tree"][ship id][node id] = rank). Each
## ship has its own tree; nodes need a rank in the node above them. Pure functions so tests can
## call them directly.

enum Gate { OPEN, NEEDS_NODE, MAXED }

const BRANCHES: Array[StringName] = [&"offense", &"defense", &"utility"]


static func ranks(state: Dictionary, ship: ShipDef) -> Dictionary:
	var tree: Dictionary = state["tree"]
	if not tree.has(String(ship.id)):
		tree[String(ship.id)] = {}
	return tree[String(ship.id)]


static func rank(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> int:
	return int(ranks(state, ship).get(String(node.id), 0))


## Whether the next rank can be bought, and if not, why.
static func gate(catalog: HangarCatalog, state: Dictionary, node: TreeNodeDef) -> Gate:
	var ship := Loadout.ship_of(catalog, state)
	if rank(state, ship, node) >= node.max_rank:
		return Gate.MAXED
	var parent := ship.node(node.requires) if node.requires != &"" else null
	return Gate.NEEDS_NODE if parent and rank(state, ship, parent) == 0 else Gate.OPEN


static func price(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> int:
	return node.cost * (rank(state, ship, node) + 1)


## Adds a rank when the gate is open. The caller pays.
static func buy(catalog: HangarCatalog, state: Dictionary, node: TreeNodeDef) -> bool:
	if gate(catalog, state, node) != Gate.OPEN:
		return false
	var ship := Loadout.ship_of(catalog, state)
	ranks(state, ship)[String(node.id)] = rank(state, ship, node) + 1
	return true


## A branch's nodes from the top down.
static func branch(ship: ShipDef, name: StringName) -> Array[TreeNodeDef]:
	var result: Array[TreeNodeDef] = []
	result.assign(ship.tree.filter(func(n: TreeNodeDef) -> bool: return n.branch == name))
	return result


## Effects of every owned node on the current ship.
static func effects(catalog: HangarCatalog, state: Dictionary) -> Array[Dictionary]:
	var ship := Loadout.ship_of(catalog, state)
	var result: Array[Dictionary] = []
	for node in ship.tree:
		var r := rank(state, ship, node)
		if r > 0:
			result.append_array(PartDef.scaled(node.effects, r))
	return result
