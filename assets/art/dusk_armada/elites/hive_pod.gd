extends Node2D
## Hive pod: a cluster of outlined amber cells that glow brighter as a swarm is about to hatch, plus
## the tether line (set_tether) back to the carrier.

const OUTLINE := Color(0.11, 0.09, 0.16)
const SHELL := Color(0.55, 0.36, 0.22)
const CELL := Color(0.95, 0.66, 0.28)
const HOT := Color(1.0, 0.95, 0.7)
const TETHER := Color(0.95, 0.75, 0.45)
const CELLS: Array[Vector2] = [Vector2(0, 0), Vector2(-14, -8), Vector2(14, -8), Vector2(-14, 9), Vector2(14, 9), Vector2(0, -17), Vector2(0, 17)]

var _tether: Variant = null
var _charge := 0.0


func set_tether(anchor: Variant) -> void:
	_tether = anchor
	queue_redraw()


## 0..1: how close the next swarm is.
func set_charge(fraction: float) -> void:
	_charge = fraction
	queue_redraw()


func _draw() -> void:
	if _tether is Vector2:
		var start: Vector2 = (_tether as Vector2).normalized() * 26.0
		draw_line(start, _tether, OUTLINE, 6.0)
		draw_line(start, _tether, TETHER, 2.0)
	draw_circle(Vector2.ZERO, 31.0, OUTLINE)
	draw_circle(Vector2.ZERO, 28.0, SHELL)
	for c in CELLS:
		_hex(c, 9.0, OUTLINE)
		_hex(c, 7.0, CELL.lerp(HOT, _charge))
	if _charge > 0.0:
		draw_arc(Vector2.ZERO, 34.0 + 6.0 * _charge, 0.0, TAU, 24, Color(HOT, _charge * 0.8), 3.0)


func _hex(center: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 6:
		points.append(center + Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * r)
	draw_colored_polygon(points, color)
