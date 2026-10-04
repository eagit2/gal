extends TestCase
## The roster sheet (data/roster/*.csv) must load cleanly and drive the enemy, elite and boss data.


func test_sheet_has_no_errors() -> void:
	expect_eq(Roster.errors.size(), 0, "errors: %s" % ", ".join(Roster.errors))


func test_every_row_is_playable() -> void:
	for id: StringName in Roster.enemy_ids():
		var def := Roster.enemy(id)
		expect_true(def.visual_scene != null and def.brain != null and def.hp > 0, id)
	for id: StringName in Roster.elite_ids():
		var def := Roster.elite(id)
		expect_true(def.visual_scene != null and def.hp > 0 and not def.traits_for_phase(0).is_empty(), id)


func test_sheet_patches_the_resources_stages_use() -> void:
	expect_true(Roster.enemy(&"bee") == load("res://data/enemies/bee.tres"), "bee is the cached .tres")
	expect_true(Roster.elite(&"puppeteer") == load("res://data/elites/puppeteer.tres"), "puppeteer too")


func test_traits_with_settings() -> void:
	var made := Roster.parse_traits("blink(interval=0.9 distance=80); plate(hp=6)", Roster.ENEMY_TRAITS, "test")
	expect_eq(made.size(), 2, "two traits")
	expect_true(made[0] is BlinkTrait and is_equal_approx(made[0].interval, 0.9) and is_equal_approx(made[0].distance, 80.0), "blink settings")
	expect_true(made[1] is PlateTrait and made[1].hp == 6, "plate hp")


func test_split_fragment_names_an_enemy() -> void:
	var made := Roster.parse_traits("split(fragment=bee count=3)", Roster.ENEMY_TRAITS, "test")
	expect_true(made[0].fragment == Roster.enemy(&"bee") and made[0].count == 3, "fragment by id")


func test_bad_trait_text_is_reported() -> void:
	var before := Roster.errors.size()
	Roster.parse_traits("blinkk; dash(speed=3)", Roster.ENEMY_TRAITS, "test")
	expect_eq(Roster.errors.size(), before + 2, "unknown trait and unknown setting")
	Roster.errors.resize(before)


func test_boss_phases() -> void:
	var boss := Roster.elite(&"matriarch")
	expect_true(boss is BossDef, "matriarch is a boss")
	expect_eq(boss.phases.size(), 3, "three phases")
	expect_eq(boss.phase_at(1.0), 0, "full hp: phase 1")
	expect_eq(boss.phase_at(0.5), 1, "half hp: phase 2")
	expect_eq(boss.phase_at(0.2), 2, "low hp: phase 3")
	expect_true(boss.traits_for_phase(2).any(func(t: EliteTrait) -> bool: return t is MeteorCallTrait), "meteors in phase 3")


func test_dev_spawn_replaces_wave_enemies() -> void:
	var opts := DevOptions.parse(PackedStringArray(["spawn=Blinker"]))
	expect_eq(opts.spawn, &"blinker", "spawn id")
	var queue := StageRunner.build_queue(load("res://data/stages/stage_1.tres"), null, Roster.enemy(&"blinker"))
	var enemies := queue.filter(func(e: Dictionary) -> bool: return e.has("enemy"))
	expect_true(enemies.all(func(e: Dictionary) -> bool: return e["enemy"] == Roster.enemy(&"blinker")), "all blinkers")
