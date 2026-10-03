extends TestCase
## Run stats from effects, scrap drop math, and combo effects.


func test_every_effect_targets_a_known_stat() -> void:
	for combo in ComboTracker.COMBOS:
		for effect: Dictionary in combo.effects:
			expect_true(UpgradeSystem.BASE_STATS.has(effect["stat"]), "%s: %s" % [combo.id, effect["stat"]])


func test_effects_stack() -> void:
	var rapid := {"stat": &"fire_rate", "op": &"mul", "value": 1.2}
	var stats := UpgradeSystem.compute([rapid, rapid] as Array[Dictionary])
	expect_true(is_equal_approx(stats[&"fire_rate"], 1.44), "1.2 * 1.2 = %f" % stats[&"fire_rate"])


func test_combo_effects_layer_on_top() -> void:
	var overdrive: ComboDef = load("res://data/combos/overdrive.tres")
	var rapid: Array[Dictionary] = [{"stat": &"fire_rate", "op": &"mul", "value": 1.2}]
	var stats := UpgradeSystem.compute(rapid + overdrive.effects)
	expect_true(is_equal_approx(stats[&"fire_rate"], 1.8), "1.2 * 1.5")


func test_combos_keep_the_screen() -> void:
	for combo in ComboTracker.COMBOS:
		expect_eq(combo.style, &"", "%s changes no art style" % combo.id)


func test_drop_chance_includes_pity() -> void:
	expect_true(is_equal_approx(DropSystem.drop_chance(0.3, 1.25, 1.4, 0.01), 0.535), "0.3*1.25*1.4 + 0.01")


func test_every_enemy_leaves_scrap() -> void:
	for file in DirAccess.get_files_at("res://data/enemies"):
		if file.ends_with(".tres"):
			var def: EnemyDef = load("res://data/enemies/" + file)
			expect_true(def.scrap > 0 and def.scrap_chance > 0.0, file)
