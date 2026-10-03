extends TestCase
## Link chips: buying, socketing, free counts and link combos.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _with_chips(chips: Dictionary) -> Dictionary:
	var state := Loadout.default_state(CATALOG)
	state["chips"] = chips
	return state


func test_store_holds_three() -> void:
	expect_eq(HangarStock.SIZE, 3, "three choices before a reroll")


func test_every_chip_and_combo_is_registered() -> void:
	expect_eq(DirAccess.get_files_at("res://data/hangar/chips").size(), CATALOG.chips.size(), "chips registered")
	expect_eq(DirAccess.get_files_at("res://data/hangar/combos").size(), CATALOG.combos.size(), "combos registered")
	for combo in CATALOG.combos:
		for id in combo.chips:
			expect_true(CATALOG.chip(id) != null, "%s uses known chip %s" % [combo.id, id])


func test_chip_from_stock() -> void:
	var state := _with_chips({})
	state["stock"] = ["power_chip"]
	expect_true(HangarStock.take_chip(state, CATALOG.chip(&"power_chip")), "bought")
	expect_eq(int(state["chips"]["power_chip"]), 1, "one owned")
	expect_true(not HangarStock.take_chip(state, CATALOG.chip(&"power_chip")), "sold out")


func test_sockets_use_free_copies() -> void:
	var state := _with_chips({"ember_chip": 1})
	var laser := CATALOG.part(&"pulse_laser")
	expect_true(Loadout.set_chip(CATALOG, state, laser, 0, &"ember_chip"), "socketed")
	expect_eq(Loadout.chips_free(state, &"ember_chip"), 0, "copy in use")
	expect_true(not Loadout.set_chip(CATALOG, state, laser, 1, &"ember_chip"), "no second copy")
	expect_true(Loadout.set_chip(CATALOG, state, laser, 0, &""), "emptied")
	expect_eq(Loadout.chips_free(state, &"ember_chip"), 1, "copy back")


func test_linked_pair_makes_a_combo() -> void:
	var combo: LinkComboDef = CATALOG.combos[0]
	var state := _with_chips({String(combo.chips[0]): 1, String(combo.chips[1]): 1})
	var part := CATALOG.part(&"needle_gun")
	expect_true(part.links > 0, "needle gun has a linked pair")
	state["parts"][String(part.id)] = {}
	var pair: Vector2i = Loadout.linked_pairs(Loadout.sockets(CATALOG, state, part))[0]
	Loadout.set_chip(CATALOG, state, part, pair.x, combo.chips[0])
	expect_true(Loadout.part_combos(CATALOG, state, part).is_empty(), "one chip is no combo")
	Loadout.set_chip(CATALOG, state, part, pair.y, combo.chips[1])
	expect_eq(Loadout.part_combos(CATALOG, state, part), [combo] as Array[LinkComboDef], "combo active")
