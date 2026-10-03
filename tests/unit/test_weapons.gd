extends TestCase
## Per-weapon shots (ShipGuns, WeaponDef barrels), chip status effects and shield layers.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _owning(ids: Array) -> Dictionary:
	var state := Loadout.default_state(CATALOG)
	for id: String in ids:
		state["parts"][id] = {}
	return state


func test_every_weapon_part_fires_its_own_shot() -> void:
	var scenes := {}
	for part in CATALOG.parts.filter(func(p: PartDef) -> bool: return p.category == PartDef.Category.WEAPON):
		expect_true(part.weapon != null, "%s has a WeaponDef" % part.id)
		if part.weapon:
			expect_eq(part.weapon.id, part.id, "%s weapon id" % part.id)
			scenes[part.weapon.projectile_scene.resource_path] = true
	expect_eq(scenes.size(), 14,"distinct projectiles (Twin Needle reuses the needle dart)")


func test_parallel_barrels_are_centred() -> void:
	expect_eq(WeaponDef.barrels(2, 14.0), [-7.0, 7.0] as Array[float])
	expect_eq(WeaponDef.barrels(1, 14.0), [0.0] as Array[float])
	expect_eq(WeaponDef.barrels(3, 0.0), [0.0, 0.0, 0.0] as Array[float], "no spacing: one muzzle")


func test_empty_nose_fires_the_basic_gun() -> void:
	var state := _owning([])
	state["mounts"]["nose"] = ""
	var guns := ShipGuns.mounted(CATALOG, state)
	expect_eq(guns.size(), 1)
	expect_eq(guns[0]["weapon"], ShipGuns.BASIC)


func test_side_weapon_fires_from_its_side() -> void:
	var state := _owning(["twin_cannon", "pulse_laser"])
	Loadout.place(CATALOG, state, &"nose", &"twin_cannon")
	Loadout.place(CATALOG, state, &"right", &"pulse_laser")
	var guns := ShipGuns.mounted(CATALOG, state)
	expect_eq(guns.size(), 2)
	expect_eq(guns[0]["mount"], &"nose", "nose first")
	expect_eq((guns[0]["weapon"] as WeaponDef).id, &"twin_cannon")
	expect_eq(guns[1]["mount"], &"right")
	expect_eq(ShipGuns.muzzle_angle(&"right"), 15.0, "right gun angles outward")
	expect_eq(ShipGuns.muzzle_angle(&"left"), -15.0, "left gun angles outward")
	expect_eq(ShipGuns.muzzle_angle(&"rear"), 0.0, "rear gun fires straight up")


func test_burn_stacks_duration_up_to_a_cap() -> void:
	expect_eq(StatusEffects.burn_after(0.0, 1), 3.0)
	expect_eq(StatusEffects.burn_after(3.0, 1), 6.0, "a second hit adds time")
	expect_eq(StatusEffects.burn_after(6.0, 1), 6.0, "capped")
	expect_eq(StatusEffects.burn_after(0.0, 2), 6.0, "longer per level")


func test_chill_slows_up_to_sixty_percent() -> void:
	expect_true(is_equal_approx(StatusEffects.chill_slow(1), 0.3))
	expect_true(is_equal_approx(StatusEffects.chill_slow(3), 0.6), "capped")
	expect_eq(StatusEffects.chill_slow(0), 0.0)


func test_chain_picks_nearest_in_range() -> void:
	var points: Array[Vector2] = [Vector2(80, 0), Vector2(200, 0), Vector2(30, 0), Vector2(0, 60)]
	expect_eq(StatusEffects.chain_targets(Vector2.ZERO, points, 2, 90.0), [2, 3] as Array[int])
	expect_eq(StatusEffects.chain_targets(Vector2.ZERO, points, 5, 90.0), [2, 3, 0] as Array[int], "never past the radius")


func test_shield_only_with_a_shield_part() -> void:
	var state := _owning(["bubble"])
	var mount := Loadout.mount_of(state, &"bubble")
	if mount == &"":
		mount = &"left"
	Loadout.place(CATALOG, state, mount, &"")
	expect_eq(UpgradeSystem.compute(Loadout.effects(CATALOG, state))[&"shield"], 0, "no shield part: no shield")
	expect_true(Loadout.place(CATALOG, state, mount, &"bubble"))
	expect_eq(UpgradeSystem.compute(Loadout.effects(CATALOG, state))[&"shield"], 1, "a fitted shield part counts")
	expect_eq(Shield.max_layers_for(0), 1)
	expect_eq(Shield.max_layers_for(2), 3, "each layer absorbs one more hit")
