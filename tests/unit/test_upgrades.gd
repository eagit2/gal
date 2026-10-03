extends TestCase
## Upgrade stacking, synergies, card rolls and drop math.

const POOL: UpgradePool = preload("res://data/upgrades/upgrade_pool.tres")


func _owned(ids: Array[StringName]) -> Array[UpgradeDef]:
	var owned: Array[UpgradeDef] = []
	for id in ids:
		owned.append(POOL.find(id))
	return owned


func test_every_upgrade_file_is_in_the_pool() -> void:
	for file in DirAccess.get_files_at("res://data/upgrades"):
		if file.ends_with(".tres") and file != "upgrade_pool.tres":
			var upgrade: UpgradeDef = load("res://data/upgrades/" + file)
			expect_true(POOL.find(upgrade.id) != null, "%s registered" % file)
	expect_eq(DirAccess.get_files_at("res://data/synergies").size(), POOL.synergies.size(), "synergies registered")


func test_every_effect_targets_a_known_stat() -> void:
	var defs: Array = POOL.upgrades + POOL.synergies + ComboTracker.COMBOS
	for def in defs:
		for effect: Dictionary in def.effects:
			var stat: StringName = effect["stat"]
			expect_true(UpgradeSystem.BASE_STATS.has(stat) or stat in UpgradeSystem.INSTANT_STATS, "%s: %s" % [def.id, stat])


func test_stacks_multiply() -> void:
	var stats := UpgradeSystem.compute(_owned([&"rapid_fire", &"rapid_fire"]), [] as Array[SynergyDef])
	expect_true(is_equal_approx(stats[&"fire_rate"], 1.44), "1.2 * 1.2 = %f" % stats[&"fire_rate"])


func test_synergy_needs_both_tags() -> void:
	var one := UpgradeSystem.compute(_owned([&"missile_pod"]), POOL.synergies)
	var both := UpgradeSystem.compute(_owned([&"missile_pod", &"seeker_rounds"]), POOL.synergies)
	expect_eq(one[&"missiles"], 1, "pod alone")
	expect_eq(both[&"missiles"], 2, "swarm adds a missile")


func test_combo_effects_layer_on_top() -> void:
	var overdrive: ComboDef = load("res://data/combos/overdrive.tres")
	var stats := UpgradeSystem.compute(_owned([&"rapid_fire"]), POOL.synergies, overdrive.effects)
	expect_true(is_equal_approx(stats[&"fire_rate"], 1.8), "1.2 * 1.5")


func test_choices_are_distinct_and_respect_requirements() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 50:
		var choices := UpgradeSystem.roll_choices(POOL, [] as Array[UpgradeDef], 3, rng)
		expect_eq(choices.size(), 3, "three cards")
		expect_true(choices[0] != choices[1] and choices[1] != choices[2] and choices[0] != choices[2], "distinct")
		for choice in choices:
			expect_true(choice.id != &"wide_spread", "wide spread needs twin shot")


func test_maxed_upgrades_are_not_offered() -> void:
	var owned := _owned([&"heavy_shells"])
	expect_true(POOL.find(&"heavy_shells") not in UpgradeSystem.available(POOL, owned), "max 1")


func test_drop_bonus_raises_rarity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 30:
		var drop := UpgradeSystem.roll_drop(POOL, [] as Array[UpgradeDef], 2, rng)
		expect_eq(drop.rarity, UpgradeDef.Rarity.EPIC, "+2 tiers is always epic")


func test_drop_chance_includes_pity() -> void:
	expect_true(is_equal_approx(DropSystem.drop_chance(0.02, 1.25, 1.4, 0.01), 0.045), "0.02*1.25*1.4 + 0.01")
