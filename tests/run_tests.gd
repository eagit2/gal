extends SceneTree
## Minimal headless test runner: godot --headless -s res://tests/run_tests.gd
## Runs every test_* method in tests/unit/test_*.gd. Exits 1 on any failure.

var failures := 0
var passed := 0


func _initialize() -> void:
	var dir := DirAccess.open("res://tests/unit")
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			_run_file("res://tests/unit/" + file)
	print("\n%d passed, %d failed" % [passed, failures])
	quit(1 if failures > 0 else 0)


func _run_file(path: String) -> void:
	var script: GDScript = load(path)
	if script == null or not script.can_instantiate():
		failures += 1
		printerr("FAIL %s: script does not compile" % path.get_file())
		return
	var suite: Object = script.new()
	for method in suite.get_method_list():
		var name: String = method["name"]
		if not name.begins_with("test_"):
			continue
		suite.set("errors", [])
		suite.call(name)
		var errors: Array = suite.get("errors")
		if errors.is_empty():
			passed += 1
		else:
			failures += 1
			printerr("FAIL %s::%s\n  %s" % [path.get_file(), name, "\n  ".join(errors)])
