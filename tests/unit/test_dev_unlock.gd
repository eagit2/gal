extends TestCase
## Dev unlock: everything owned, tree nodes toggle for free.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")


func test_grant_all_owns_everything() -> void:
	var state := Loadout.default_state(CATALOG)
	DevUnlock.grant_all(CATALOG, state)
	for def in CATALOG.parts:
		expect_true(Loadout.owns(state, def.id), "owns %s" % def.id)
	for i in CATALOG.ships.size():
		var id: StringName = CATALOG.ships[i].id
		expect_true(Loadout.unlocked(state, CATALOG.ship(id)), "%s unlocked" % id)
	expect_eq((state["pilots"] as Array).size(), CATALOG.pilots.size(), "every pilot")
	for def in CATALOG.chips:
		expect_eq(Loadout.chips_free(state, def.id), DevUnlock.CHIP_COPIES, "%s copies" % def.id)


func test_toggle_closes_partner_and_clears_children() -> void:
	var state := Loadout.default_state(CATALOG)
	var ship := Loadout.ship_of(CATALOG, state)
	var forked: TreeNodeDef = null
	for node in ship.tree:
		if node.excludes != &"":
			forked = node
			break
	var partner := ship.node(forked.excludes)
	DevUnlock.toggle(state, ship, partner)
	expect_eq(ShipTree.rank(state, ship, partner), 1, "on without parents")
	DevUnlock.toggle(state, ship, forked)
	expect_eq(ShipTree.rank(state, ship, partner), 0, "partner closed")
	for i in forked.max_rank - 1:
		DevUnlock.toggle(state, ship, forked)
	expect_eq(ShipTree.rank(state, ship, forked), forked.max_rank, "steps to max")
	DevUnlock.toggle(state, ship, forked)
	expect_eq(ShipTree.rank(state, ship, forked), 0, "max wraps to off")
