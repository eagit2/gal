extends Node2D
## A shoot-off cannon on the Iron Fortress. Chars as it takes damage and flashes before it fires.

const OUTLINE := Color(0.11, 0.09, 0.16)

var _damage := 0.0
var _charge := false
var _t := 0.0


func set_damage(fraction: float) -> void:
	_damage = fraction


func set_charge(on: bool) -> void:
	_charge = on


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var metal := Color(0.55, 0.6, 0.7).lerp(Color(0.3, 0.2, 0.18), _damage)
	draw_rect(Rect2(-5, 2, 10, 14), OUTLINE)
	draw_rect(Rect2(-3.5, 3, 7, 12), Color(0.35, 0.38, 0.45))
	draw_circle(Vector2.ZERO, 12.0, OUTLINE)
	draw_circle(Vector2.ZERO, 10.0, metal)
	var glow := Color(1.0, 0.8, 0.3) if _charge and fmod(_t, 0.12) < 0.06 else Color(0.9, 0.3, 0.2)
	draw_circle(Vector2(0, 1), 3.5, glow)
