class_name HangarRules
extends RefCounted
## Hangar purchase rules and the effects owned ranks give. Pure functions on a ranks
## dictionary ({node_id: rank}) so tests can call them directly.


static func rank_of(ranks: Dictionary, id: StringName) -> int:
	return int(ranks.get(String(id), 0))


## Credits for the next rank, or -1 when maxed.
static func next_cost(node: HangarNodeDef, ranks: Dictionary) -> int:
	var rank := rank_of(ranks, node.id)
	return node.costs[rank] if rank < node.max_rank() else -1


static func is_unlocked(node: HangarNodeDef, ranks: Dictionary) -> bool:
	return node.requires.all(func(r: StringName) -> bool: return rank_of(ranks, r) > 0)


static func can_buy(node: HangarNodeDef, ranks: Dictionary, credits: int) -> bool:
	var cost := next_cost(node, ranks)
	return cost >= 0 and cost <= credits and is_unlocked(node, ranks)


## Effects of every owned rank, for GameState.set_meta_effects.
static func effects(tree: HangarTree, ranks: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in tree.nodes:
		for i in mini(rank_of(ranks, node.id), node.max_rank()):
			result.append_array(node.effects)
	return result


static func payout(medal: MedalDef, currency_mult: float) -> int:
	return roundi(medal.currency * currency_mult)
