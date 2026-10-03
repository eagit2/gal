class_name TreeLines
extends Control
## Draws the ship tree's connectors behind its nodes: [{"from": Vector2, "to": Vector2, "color":
## Color}] as right-angled lines (up from `from`, across, up into `to`), plus straight `bars`.

const WIDTH := 4.0

var elbows: Array[Dictionary] = []
var bars: Array[Dictionary] = []


func _draw() -> void:
	for e in elbows:
		var a: Vector2 = e["from"]
		var b: Vector2 = e["to"]
		var mid := roundf((a.y + b.y) / 2.0)
		var points := PackedVector2Array([a, Vector2(a.x, mid), Vector2(b.x, mid), b])
		draw_polyline(points, e["color"], WIDTH)
	for bar in bars:
		draw_line(bar["from"], bar["to"], bar["color"], WIDTH)
