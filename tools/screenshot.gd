extends SceneTree
## Renders the game and saves screenshots (needs a display; in containers use xvfb-run).
## xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60 --resolution 540x960 -s res://tools/screenshot.gd -- --at=5,20 --out=/tmp/shot [--nofire] [stage=N]
## stage=N is read by the game (DevOptions, 1-based or a stage id).
var g: Node
var f := 0
var shots := {}
var out := ""
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
		elif a.begins_with("--at="):
			for s in a.get_slice("=", 1).split(","): shots[int(s) * 60] = true
	g = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(g)
func _process(_d: float) -> bool:
	f += 1
	if not "--nofire" in OS.get_cmdline_user_args(): Input.action_press("fire")
	if shots.has(f):
		root.get_texture().get_image().save_png("%s_%d.png" % [out, f / 60])
	if f > shots.keys().max():
		g.free(); quit(); return true
	return false
