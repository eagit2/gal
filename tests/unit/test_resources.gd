extends TestCase
## Content data classes must load and have sane defaults.


func test_difficulty_defaults() -> void:
	var d := DifficultyDef.new()
	expect_eq(d.lives, 3, "lives")


func test_upgrade_defaults() -> void:
	var u := UpgradeDef.new()
	expect_eq(u.rarity, UpgradeDef.Rarity.COMMON, "rarity")
	expect_eq(u.max_stacks, 1, "max_stacks")
