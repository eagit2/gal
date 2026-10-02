class_name TestCase
extends RefCounted
## Base class for unit tests. Use expect_* helpers; the runner reads `errors`.

var errors: Array = []


func expect_eq(actual: Variant, expected: Variant, label: String = "") -> void:
	if actual != expected:
		errors.append("%s expected %s, got %s" % [label, str(expected), str(actual)])


func expect_true(value: bool, label: String = "") -> void:
	if not value:
		errors.append("%s expected true" % label)
