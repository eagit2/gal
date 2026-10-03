extends TestCase
## Content data classes must load and have sane defaults.


func test_difficulty_defaults() -> void:
	var d := DifficultyDef.new()
	expect_eq(d.lives, 1, "lives")


