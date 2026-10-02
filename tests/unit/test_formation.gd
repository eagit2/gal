extends TestCase


func test_slots_are_symmetric_and_inside_screen() -> void:
	var formation := Formation.new()
	var left := formation.slot_position(Vector2i(0, 0))
	var right := formation.slot_position(Vector2i(Formation.COLUMNS - 1, 0))
	expect_eq(roundi(left.x + right.x), 540, "centered")
	expect_true(left.x > 20.0 and right.x < 520.0, "inside screen")
	expect_true(formation.slot_position(Vector2i(0, 1)).y > left.y, "rows go down")
	formation.free()
