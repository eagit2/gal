extends TestCase
## Hangar purchase rules, rank effects, medal goals and payouts.

const TREE: HangarTree = preload("res://data/hangar/hangar_tree.tres")


func _medal(goal: MedalDef.Goal, target := 0.0) -> MedalDef:
	var medal := MedalDef.new()
	medal.goal = goal
	medal.target = target
	medal.currency = 20
	return medal


func test_every_node_file_is_in_the_tree() -> void:
	var files := Array(DirAccess.get_files_at("res://data/hangar")).filter(func(f: String) -> bool: return f.ends_with(".tres") and f != "hangar_tree.tres")
	expect_eq(files.size(), TREE.nodes.size(), "nodes registered")


func test_every_node_effect_targets_a_known_stat() -> void:
	for node in TREE.nodes:
		expect_true(node.max_rank() > 0, "%s has costs" % node.id)
		for effect: Dictionary in node.effects:
			expect_true(UpgradeSystem.BASE_STATS.has(effect["stat"]), "%s: %s" % [node.id, effect["stat"]])
		for id in node.requires:
			expect_true(TREE.find(id) != null, "%s requires %s" % [node.id, id])


func test_buy_rules() -> void:
	var node := TREE.find(&"thruster_tuning")
	var ranks := {}
	expect_eq(HangarRules.next_cost(node, ranks), 30)
	expect_true(not HangarRules.can_buy(node, ranks, 29), "too poor")
	expect_true(HangarRules.can_buy(node, ranks, 30), "affordable")
	ranks["thruster_tuning"] = node.max_rank()
	expect_eq(HangarRules.next_cost(node, ranks), -1, "maxed")
	expect_true(not HangarRules.can_buy(node, ranks, 9999), "maxed can't buy")


func test_requirements_lock_nodes() -> void:
	var node := TREE.find(&"reinforced_bubble")
	expect_true(not HangarRules.can_buy(node, {}, 9999), "locked")
	expect_true(HangarRules.can_buy(node, {"shield_capacitor": 1.0}, 9999), "unlocked (JSON floats)")


func test_ranks_stack_into_stats() -> void:
	var ranks := {"thruster_tuning": 2, "wing_drone": 1}
	var stats := UpgradeSystem.compute([], [], HangarRules.effects(TREE, ranks))
	expect_true(is_equal_approx(stats[&"move_speed"], 1.05 * 1.05), "two ranks multiply")
	expect_eq(stats[&"drones"], 1)
	expect_eq(HangarRules.effects(TREE, {}).size(), 0, "nothing owned")


func test_medal_goals() -> void:
	var tracker := MedalTracker.new(_medal(MedalDef.Goal.NO_DAMAGE))
	expect_true(tracker.earned(), "no damage yet")
	tracker.ships_lost = 1
	expect_true(not tracker.earned(), "lost a ship")
	tracker = MedalTracker.new(_medal(MedalDef.Goal.ACCURACY, 0.6))
	expect_true(not tracker.earned(), "no shots fired")
	tracker.shots = 10
	tracker.hits = 6
	expect_true(tracker.earned(), "60% accuracy")
	tracker = MedalTracker.new(_medal(MedalDef.Goal.PERFECT))
	tracker.escapes = 1
	expect_true(not tracker.earned(), "one escaped")
	expect_true(not MedalTracker.new(null).earned(), "stage without medal")


func test_payout_scales_with_difficulty() -> void:
	var medal := _medal(MedalDef.Goal.NO_DAMAGE)
	expect_eq(HangarRules.payout(medal, 1.0), 20)
	expect_eq(HangarRules.payout(medal, 2.5), 50)
	expect_eq(HangarRules.payout(medal, 0.75), 15)


func test_sector_1_stages_have_medals() -> void:
	for stage in (load("res://data/sectors/sector_1.tres") as SectorDef).stages:
		expect_true(stage.medal != null, "%s medal" % stage.id)
