extends TestCase
## The design-board weapons: Flak Cannon, Rail Spike, Scrap Cannon, Twin Needle, Mine Launcher,
## Rubber Duck Gun, Bubble Blower, Ball Lightning, Hypno Gun and Gravity Gun.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")
const IDS: Array[StringName] = [&"flak_cannon", &"rail_spike", &"scrap_cannon", &"twin_needle", &"mine_launcher", &"rubber_duck_gun", &"bubble_blower", &"ball_lightning", &"hypno_gun", &"gravity_gun"]
## Stats a track may never raise, per weapon (design rules).
const NEVER := {
	&"flak_cannon": [&"projectile_speed"],
	&"rail_spike": [&"spread", &"extra_shots"],
	&"scrap_cannon": [&"fire_rate"],
	&"twin_needle": [&"damage"],
	&"mine_launcher": [&"homing"],
	&"rubber_duck_gun": [&"pierce"],
	&"bubble_blower": [&"fire_rate"],
	&"ball_lightning": [&"fire_rate"],
	&"hypno_gun": [&"damage"],
	&"gravity_gun": [&"damage"],
}


func test_each_part_is_a_weapon_with_two_tracks() -> void:
	for id in IDS:
		var def := CATALOG.part(id)
		expect_true(def != null, "%s in catalog" % id)
		if def == null:
			continue
		expect_eq(def.category, PartDef.Category.WEAPON, "%s category" % id)
		expect_true(def.weapon != null and def.weapon.id == id, "%s weapon" % id)
		expect_true(def.weapon.projectile_scene != null, "%s projectile" % id)
		expect_eq(def.attributes.size(), 2, "%s tracks" % id)
		for a in def.attributes:
			for e: Dictionary in a["effects"]:
				expect_true(not (e["stat"] in NEVER[id]), "%s never raises %s" % [id, e["stat"]])


func test_fire_rate_tracks_follow_the_pattern() -> void:
	for id in IDS:
		var def := CATALOG.part(id)
		for a in def.attributes:
			if a["effects"][0]["stat"] == &"fire_rate":
				expect_eq(int(a["max"]), 5, "%s rate max" % id)
				expect_true(a.has("final") and is_equal_approx(float(a["final"][0]["value"]), 1.0), "%s final jump" % id)


func test_projectile_scenes_use_their_scripts() -> void:
	var expected := {&"scrap_cannon": ScrapBall, &"mine_launcher": PlayerMine, &"rubber_duck_gun": RubberDuck, &"bubble_blower": BubbleShot,
		&"ball_lightning": BallLightning, &"hypno_gun": HypnoOrb, &"gravity_gun": GravityWell}
	for id: StringName in expected:
		var shot := CATALOG.part(id).weapon.projectile_scene.instantiate()
		expect_true(is_instance_of(shot, expected[id]), "%s shot script" % id)
		shot.free()


func test_flak_pellets_fan_and_add_with_level() -> void:
	var flak := CATALOG.part(&"flak_cannon").weapon
	expect_eq(flak.shot_angles().size(), 5, "base pellets")
	expect_true(flak.max_range > 0.0 and flak.max_range <= 260.0, "short range")
	var stats := UpgradeSystem.compute(CATALOG.part(&"flak_cannon").effects_at({"pellets": 2}))
	var angles := WeaponDef.fan(flak.spread_count + stats[&"extra_shots"], flak.spread_angle)
	expect_eq(angles.size(), 7, "two pellet levels")
	expect_true(is_equal_approx(angles[0], -angles[6]), "symmetric cone")


func test_rail_spike_is_wide_and_pierces_everything() -> void:
	var rail := CATALOG.part(&"rail_spike").weapon
	var shot := rail.projectile_scene.instantiate()
	var shape := (shot.get_node(^"Shape") as CollisionShape2D).shape as RectangleShape2D
	expect_true(is_equal_approx(shape.size.x, 54.0), "a tenth of the screen wide")
	expect_true(rail.pierce >= 100, "pierces everything")
	expect_true(rail.fire_rate < 1.0, "long reload")
	shot.free()


func test_scrap_breaks_into_shrapnel_evenly() -> void:
	expect_eq(ScrapBall.shrapnel_angles(4), [0.0, 90.0, 180.0, 270.0] as Array[float])
	expect_eq(ScrapBall.shrapnel_angles(0).size(), 0, "no shrapnel")
	var stats := UpgradeSystem.compute(CATALOG.part(&"scrap_cannon").effects_at({"shrapnel": 3}))
	expect_eq(CATALOG.part(&"scrap_cannon").weapon.shrapnel + int(stats[&"shrapnel"]), 6, "maxed shrapnel")


func test_twin_needle_fires_two_parallel_lines() -> void:
	var twin := CATALOG.part(&"twin_needle").weapon
	expect_eq(twin.shot_angles(), [0.0, 0.0] as Array[float])
	var offsets := WeaponDef.barrels(twin.spread_count, twin.spacing)
	expect_true(offsets.size() == 2 and offsets[0] < 0.0 and is_equal_approx(offsets[0], -offsets[1]), "parallel barrels")
	expect_true(twin.projectile_scene == CATALOG.part(&"needle_gun").weapon.projectile_scene, "reuses needle darts")


func test_mine_cap() -> void:
	var mines := CATALOG.part(&"mine_launcher").weapon
	expect_eq(mines.cap(0), 3, "base cap")
	expect_eq(mines.cap(2), 5, "mines out levels")
	expect_true(WeaponDef.can_fire(2, 3) and not WeaponDef.can_fire(3, 3), "capped at the limit")
	expect_true(WeaponDef.can_fire(50, CATALOG.part(&"pulse_laser").weapon.cap(4)), "uncapped weapons")
	expect_true(PlayerMine.in_blast(Vector2.ZERO, Vector2(60, 60), 90.0), "inside the blast")
	expect_true(not PlayerMine.in_blast(Vector2.ZERO, Vector2(70, 70), 90.0), "outside the blast")
	var stats := UpgradeSystem.compute(CATALOG.part(&"mine_launcher").effects_at({"blast": 2}))
	expect_true(is_equal_approx(mines.blast_radius + stats[&"blast_radius"], 120.0), "blast radius levels")


func test_duck_bounces() -> void:
	var arena := Rect2(10, 60, 520, 2000)
	expect_eq(RubberDuck.wall_bounce(Vector2(5, 300), Vector2(-100, -300), arena), Vector2(100, -300), "left wall")
	expect_eq(RubberDuck.wall_bounce(Vector2(535, 300), Vector2(100, -300), arena), Vector2(-100, -300), "right wall")
	expect_eq(RubberDuck.wall_bounce(Vector2(200, 50), Vector2(100, -300), arena), Vector2(100, 300), "top wall")
	expect_eq(RubberDuck.wall_bounce(Vector2(5, 300), Vector2(100, -300), arena), Vector2(100, -300), "already leaving")
	var duck := CATALOG.part(&"rubber_duck_gun").weapon
	expect_eq(RubberDuck.wall_bounce_limit(duck.bounces), 3, "3 wall bounces")
	expect_eq(RubberDuck.wall_bounce_limit(duck.bounces + 4), 3, "never more than 3")
	var stats := UpgradeSystem.compute(CATALOG.part(&"rubber_duck_gun").effects_at({"power": 3}))
	expect_eq(int(stats[&"bounces"]), 0, "no track adds bounces")
	expect_eq(duck.pierce + int(stats[&"pierce"]), 0, "never pierces")


func test_bubble_traps_only_regular_enemies() -> void:
	expect_true(BubbleShot.traps(true, false, false), "regular enemy")
	expect_true(not BubbleShot.traps(true, true, false), "plated")
	expect_true(not BubbleShot.traps(false, false, false), "elite or other")
	expect_true(not BubbleShot.traps(true, false, true), "already trapped")
	var stats := UpgradeSystem.compute(CATALOG.part(&"bubble_blower").effects_at({"size": 4}))
	expect_true(is_equal_approx(stats[&"shot_size"], 1.6), "bubble size levels")
	expect_eq(BubbleShot.MAX_TRAPS, 3, "traps up to 3")
	expect_true(BubbleShot.keeps_going(3) and BubbleShot.keeps_going(2), "keeps going after 1 and 2 traps")
	expect_true(not BubbleShot.keeps_going(1), "done after the third")


func test_scrap_cannon_is_slow_and_big() -> void:
	var scrap := CATALOG.part(&"scrap_cannon").weapon
	expect_true(scrap.fire_rate <= 0.75, "slower cannon")
	var shot := scrap.projectile_scene.instantiate()
	var shape := (shot.get_node(^"Shape") as CollisionShape2D).shape as CircleShape2D
	expect_true(is_equal_approx(shape.radius, 34.0), "double-size ball")
	shot.free()


func test_ball_lightning_wanders_on_screen_and_ticks() -> void:
	var ball := CATALOG.part(&"ball_lightning").weapon
	expect_true(ball.fire_rate < 1.0 and ball.projectile_speed < 200.0, "slow cadence, slow drift")
	expect_true(BallLightning.wander_drift(20.0, -1.0) > 0.0, "left edge drifts right")
	expect_true(BallLightning.wander_drift(520.0, 1.0) < 0.0, "right edge drifts left")
	expect_true(is_equal_approx(BallLightning.wander_drift(270.0, -0.5), -0.5 * BallLightning.WANDER_SPEED), "free in the middle")
	var left := BallLightning.tick_cooldowns({"a": 0.3, "b": 0.1}, 0.2)
	expect_true(left.has("a") and not left.has("b"), "finished cooldowns drop")
	expect_true(is_equal_approx(float(left["a"]), 0.1), "cooldown counts down")
	var stats := UpgradeSystem.compute(CATALOG.part(&"ball_lightning").effects_at({"size": 3}))
	expect_true(is_equal_approx(stats[&"ball_size"], 1.6), "ball size levels")


func test_hypno_picks_targets_and_modes() -> void:
	expect_true(HypnoControl.can_hypnotize(true, false, false), "regular enemy")
	expect_true(not HypnoControl.can_hypnotize(false, false, false), "elite or other")
	expect_true(not HypnoControl.can_hypnotize(true, true, false), "already hypnotized")
	expect_true(not HypnoControl.can_hypnotize(true, false, true), "in a bubble")
	expect_eq(HypnoControl.pick_mode(0.2), HypnoControl.Mode.KAMIKAZE)
	expect_eq(HypnoControl.pick_mode(0.8), HypnoControl.Mode.SHOOT)
	expect_eq(HypnoControl.nearest(Vector2.ZERO, [Vector2(100, 0), Vector2(0, 30), Vector2(-50, 0)] as Array[Vector2]), 1)
	expect_eq(HypnoControl.nearest(Vector2.ZERO, [] as Array[Vector2]), -1)
	var stats := UpgradeSystem.compute(CATALOG.part(&"hypno_gun").effects_at({"hypno_time": 3}))
	expect_true(is_equal_approx(HypnoControl.BASE_TIME + stats[&"hypno_time"], 7.0), "hypno time levels")


func test_gravity_well_pulls_and_holds_short() -> void:
	var gun := CATALOG.part(&"gravity_gun").weapon
	expect_true(is_equal_approx(1.0 / gun.fire_rate, 5.0), "one well every 5 s")
	expect_eq(GravityWell.pull_step(Vector2(100, 0), Vector2.ZERO, 30.0, 20.0), Vector2(70, 0))
	expect_eq(GravityWell.pull_step(Vector2(30, 0), Vector2.ZERO, 30.0, 20.0), Vector2(20, 0), "stops short")
	expect_eq(GravityWell.pull_step(Vector2(10, 0), Vector2.ZERO, 30.0, 20.0), Vector2(10, 0), "already close")
	var stats := UpgradeSystem.compute(CATALOG.part(&"gravity_gun").effects_at({"pull_time": 3, "pull_radius": 3}))
	expect_true(is_equal_approx(GravityWell.BASE_PULL_TIME + stats[&"pull_time"], 3.5), "pull time levels")
	expect_true(is_equal_approx(GravityWell.BASE_PULL_RADIUS + stats[&"pull_radius"], 240.0), "pull radius levels")


func test_new_stats_have_words() -> void:
	for stat: StringName in [&"ball_size", &"hypno_time", &"pull_time", &"pull_radius"]:
		expect_true(UpgradeSystem.BASE_STATS.has(stat), "%s is a run stat" % stat)
		expect_true(StatWords.FORMATS.has(stat), "%s has words" % stat)
