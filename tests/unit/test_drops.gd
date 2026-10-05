extends TestCase
## Item and power-up drops (DropSystem, Powerups, DropTable).

const TABLE: DropTable = preload("res://data/drops/drop_table.tres")
const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")


func test_rates_match_the_plan() -> void:
	expect_true(is_equal_approx(TABLE.enemy_item, 0.005), "enemy item 0.5%")
	expect_true(is_equal_approx(TABLE.elite_item, 0.05), "elite item 5%")
	expect_true(is_equal_approx(TABLE.enemy_powerup, 0.015), "enemy power-up 1.5%")
	expect_true(is_equal_approx(TABLE.elite_powerup, 0.25), "elite power-up 25%")
	expect_true(is_equal_approx(TABLE.boss_powerup, 1.0), "boss power-up always")


func test_one_drop_by_priority() -> void:
	var S := DropSystem.Source
	expect_eq(DropSystem.pick(S.ENEMY, TABLE, 0.001, 0.001), &"item", "item beats power-up")
	expect_eq(DropSystem.pick(S.ENEMY, TABLE, 0.5, 0.01), &"powerup", "power-up when no item")
	expect_eq(DropSystem.pick(S.ENEMY, TABLE, 0.5, 0.5), &"", "else scrap")
	expect_eq(DropSystem.pick(S.BOSS, TABLE, 0.9, 0.99), &"powerup", "bosses always drop something")


func test_enemies_never_drop_chips_or_story_parts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 200:
		var item := DropSystem.pick_item(DropSystem.Source.ENEMY, TABLE, CATALOG, rng)
		expect_eq(item["kind"], &"part", "enemy drops are parts")
		var part := CATALOG.part(item["id"])
		expect_true(not part.unique and int(part.tier) in TABLE.enemy_tiers, "%s is a common part" % part.id)
	var chips := 0
	for i in 200:
		var item := DropSystem.pick_item(DropSystem.Source.ELITE, TABLE, CATALOG, rng)
		chips += 1 if item["kind"] == &"chip" else 0
		if item["kind"] == &"chip":
			expect_true(CATALOG.chip(item["id"]) != null, "%s is a chip" % item["id"])
	expect_true(chips > 50 and chips < 150, "elites drop chips about half the time")


func test_power_and_rate_multiply_up_to_double() -> void:
	var counts := Powerups.empty()
	expect_true(Powerups.add(counts, &"power", TABLE), "first pickup")
	expect_true(Powerups.add(counts, &"power", TABLE), "second pickup")
	expect_true(is_equal_approx(Powerups.power_mult(counts, TABLE), 1.21), "x1.1 x1.1")
	for i in 20:
		Powerups.add(counts, &"power", TABLE)
	expect_true(is_equal_approx(Powerups.power_mult(counts, TABLE), 2.0), "capped at x2")
	expect_true(not Powerups.add(counts, &"power", TABLE), "a pickup past the cap pays scrap instead")


func test_extra_shots_stack_to_three() -> void:
	var counts := Powerups.empty()
	for i in 3:
		expect_true(Powerups.add(counts, &"shots", TABLE), "shot %d" % i)
	expect_true(not Powerups.add(counts, &"shots", TABLE), "a fourth is capped")
	var stats := UpgradeSystem.compute(Powerups.effects(counts, TABLE))
	expect_eq(stats[&"volleys"], 3, "three extra volleys")
	expect_eq(Powerups.hud_text({&"power": 2, &"rate": 1, &"shots": 1}), "P2 F1 +1", "HUD stacks")


func test_fire_rate_power_up_scales_the_hangar_rate() -> void:
	var counts := {&"power": 0, &"rate": 1, &"shots": 0}
	var hangar: Array[Dictionary] = [{"stat": &"fire_rate", "op": &"add", "value": 0.5}]
	var stats := UpgradeSystem.compute(hangar + Powerups.effects(counts, TABLE))
	expect_true(is_equal_approx(stats[&"fire_rate"], 1.65), "1.5 x 1.1")


func test_damage_rounds_by_chance() -> void:
	expect_eq(Powerups.scaled_damage(1, 1.1, 0.05), 2, "low roll adds the fraction")
	expect_eq(Powerups.scaled_damage(1, 1.1, 0.5), 1, "high roll keeps the whole")
	expect_eq(Powerups.scaled_damage(3, 2.0, 0.99), 6, "whole multiples are exact")


func test_losing_a_life_clears_power_ups() -> void:
	GameState.start_run(&"pilot", 3)
	GameState.add_powerup(&"shots")
	GameState.add_powerup(&"power")
	expect_eq(GameState.stats[&"volleys"], 1, "held")
	GameState.lose_life()
	expect_eq(GameState.powerups, Powerups.empty(), "cleared")
	expect_eq(GameState.stats[&"volleys"], 0, "stats back to base")
	expect_true(is_equal_approx(GameState.stats[&"power_mult"], 1.0), "power back to base")


func test_story_parts_are_never_sold() -> void:
	var state := Loadout.default_state(CATALOG)
	var rng := RandomNumberGenerator.new()
	for i in 50:
		HangarStock.roll(CATALOG, state, rng)
		expect_true(not "mentor_needle" in (state["stock"] as Array), "not in stock")
