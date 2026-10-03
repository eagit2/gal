extends TestCase
## The design-board weapons: Flak Cannon, Rail Spike, Scrap Cannon, Twin Needle, Mine Launcher,
## Rubber Duck Gun and Bubble Blower.

const CATALOG: HangarCatalog = preload("res://data/hangar/catalog.tres")
const IDS: Array[StringName] = [&"flak_cannon", &"rail_spike", &"scrap_cannon", &"twin_needle", &"mine_launcher", &"rubber_duck_gun", &"bubble_blower"]
## Stats a track may never raise, per weapon (design rules).
const NEVER := {
	&"flak_cannon": [&"projectile_speed"],
	&"rail_spike": [&"spread", &"extra_shots"],
	&"scrap_cannon": [&"fire_rate"],
	&"twin_needle": [&"damage"],
	&"mine_launcher": [&"homing"],
	&"rubber_duck_gun": [&"pierce"],
	&"bubble_blower": [&"fire_rate"],
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
	var expected := {&"scrap_cannon": ScrapBall, &"mine_launcher": PlayerMine, &"rubber_duck_gun": RubberDuck, &"bubble_blower": BubbleShot}
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
	var to_near := RubberDuck.bounce_direction(Vector2(100, 300), [Vector2(400, 300), Vector2(100, 200)] as Array[Vector2], 1.0)
	expect_true(to_near.is_equal_approx(Vector2.UP), "chases the nearest enemy")
	var away := RubberDuck.bounce_direction(Vector2(100, 300), [] as Array[Vector2], -5.0)
	expect_true(away.x < 0.0 and away.y < 0.0, "up and away with nothing near")
	var duck := CATALOG.part(&"rubber_duck_gun").weapon
	expect_eq(1 + duck.bounces, 4, "up to 4 hits")


func test_bubble_traps_only_regular_enemies() -> void:
	expect_true(BubbleShot.traps(true, false, false), "regular enemy")
	expect_true(not BubbleShot.traps(true, true, false), "plated")
	expect_true(not BubbleShot.traps(false, false, false), "elite or other")
	expect_true(not BubbleShot.traps(true, false, true), "already trapped")
	var stats := UpgradeSystem.compute(CATALOG.part(&"bubble_blower").effects_at({"size": 4}))
	expect_true(is_equal_approx(stats[&"shot_size"], 1.6), "bubble size levels")
