class_name ShipTree
extends RefCounted
## Ship skill tree rules on the saved loadout state (state["tree"][ship id][node id] = rank). Each
## ship has its own tree. A node needs ranks in the nodes it hangs from (all of them, or `needs` of
## them); fork partners close each other. Pure functions so tests can call them directly.

enum Gate { OPEN, NEEDS_NODE, CLOSED, MAXED }

const BRANCHES: Array[StringName] = [&"offense", &"defense", &"utility", &"merge", &"capstone"]


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
	var partner := ship.node(node.excludes) if node.excludes != &"" else null
	if partner and rank(state, ship, partner) > 0:
		return Gate.CLOSED
	var owned := 0
	for id in node.requires:
		var parent := ship.node(id)
		if parent and rank(state, ship, parent) > 0:
			owned += 1
	var needed := node.needs if node.needs > 0 else node.requires.size()
	return Gate.OPEN if owned >= needed else Gate.NEEDS_NODE


## Names of the nodes `node` hangs from, for "Needs ..." lines.
static func needs_text(ship: ShipDef, node: TreeNodeDef) -> String:
	var names: PackedStringArray = []
	for id in node.requires:
		names.append(ship.node(id).display_name.to_upper())
	if node.needs > 0 and node.needs < names.size():
		return "any %d of %s" % [node.needs, ", ".join(names)]
	return " + ".join(names)


static func price(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> int:
	return node.cost * (rank(state, ship, node) + 1)


## Adds a rank when the gate is open. The caller pays.
static func buy(catalog: HangarCatalog, state: Dictionary, node: TreeNodeDef) -> bool:
	if gate(catalog, state, node) != Gate.OPEN:
		return false
	var ship := Loadout.ship_of(catalog, state)
	ranks(state, ship)[String(node.id)] = rank(state, ship, node) + 1
	return true


## Effects of every owned node on the current ship.
static func effects(catalog: HangarCatalog, state: Dictionary) -> Array[Dictionary]:
	var ship := Loadout.ship_of(catalog, state)
	var result: Array[Dictionary] = []
	for node in ship.tree:
		var r := rank(state, ship, node)
		if r > 0:
			result.append_array(PartDef.scaled(node.effects, r))
	return result


## Link sockets the current ship's tree adds to every part of `category`.
static func extra_sockets(catalog: HangarCatalog, state: Dictionary, category: int) -> int:
	var ship := Loadout.ship_of(catalog, state)
	var total := 0
	for node in ship.tree:
		if node.socket_category == category:
			total += rank(state, ship, node)
	return total
