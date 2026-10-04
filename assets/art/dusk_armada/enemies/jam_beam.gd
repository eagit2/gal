extends Node2D
## Jammer beam: a thin warning line that tightens and brightens while charging, then a bright flash.

const LENGTH := 1400.0
const WARN := Color(1.0, 0.3, 0.9)

var _dir := Vector2.DOWN
var _width := 28.0
var _charge := 0.0
var _flash := -1.0


func aim(direction: Vector2, width: float) -> void:
	_dir = direction
	_width = width
	queue_redraw()


func set_charge(fraction: float) -> void:
	_charge = clampf(fraction, 0.0, 1.0)
	queue_redraw()


func fire() -> void:
	_flash = 0.0


func _process(delta: float) -> void:
	if _flash >= 0.0:
		_flash += delta
		if _flash > 0.18:
			queue_free()
			return
		queue_redraw()


func _draw() -> void:
	var tip := _dir * LENGTH
	if _flash >= 0.0:
		var a := 1.0 - _flash / 0.18
		draw_line(Vector2.ZERO, tip, Color(WARN, 0.5 * a), _width)
		draw_line(Vector2.ZERO, tip, Color(1, 1, 1, a), _width * 0.4)
		return
	# Edges of the danger zone close in on a core line as the charge completes.
	var half := _width * 0.5
	var side := _dir.rotated(PI / 2.0)
	var edge := half * (1.0 - 0.7 * _charge)
	draw_line(side * edge, side * edge + tip, Color(WARN, 0.35 + 0.4 * _charge), 2.0)
	draw_line(-side * edge, -side * edge + tip, Color(WARN, 0.35 + 0.4 * _charge), 2.0)
	draw_line(Vector2.ZERO, tip, Color(WARN, 0.2 + 0.6 * _charge), 1.0 + 3.0 * _charge)
