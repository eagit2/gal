extends TestCase


func test_take_damage_emits_died_once() -> void:
	var health := Health.new()
	health.reset(2)
	var deaths := [0]
	health.died.connect(func() -> void: deaths[0] += 1)
	health.take_damage(1)
	expect_eq(health.hp, 1, "hp after 1 damage")
	health.take_damage(5)
	health.take_damage(1)
	expect_eq(health.hp, 0, "hp floors at 0")
	expect_eq(deaths[0], 1, "died emitted once")
	health.free()
