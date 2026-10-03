extends Node2D
## Procedural asteroid for towed rocks and their chunks: a jagged outlined polygon with craters,
## scaled by set_size(), plus the tether line (set_tether) back to the elite.

const OUTLINE := Color(0.11, 0.09, 0.16)
const BODY := Color(0.43, 0.37, 0.42)
const LIGHT := Color(0.62, 0.53, 0.52)
const CRATER := Color(0.3, 0.25, 0.31)
const TETHER := Color(0.95, 0.75, 0.45)

@export var radius := 52.0
@export var points := 14
@export var craters := 4
var _size := 1.0
var _tether: Variant = null
var _shape := PackedVector2Array()
var _craters: Array[Vector3] = []  # x, y, r in unit space


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id()
	for i in points:
		_shape.append(Vector2.from_angle(TAU * i / points) * rng.randf_range(0.78, 1.0))
	for i in craters:
		var at := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 0.55)
		_craters.append(Vector3(at.x, at.y, rng.randf_range(0.12, 0.22)))


func set_size(fraction: float) -> void:
	_size = fraction
	queue_redraw()


## Tether end relative to the rock, or null once cut.
func set_tether(anchor: Variant) -> void:
	_tether = anchor
	queue_redraw()


func _draw() -> void:
	var r := radius * _size
	if _tether is Vector2:
		var start: Vector2 = (_tether as Vector2).normalized() * r * 0.9
		draw_line(start, _tether, OUTLINE, 6.0)
		draw_line(start, _tether, TETHER, 2.0)
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var light := PackedVector2Array()
	for p in _shape:
		outer.append(p * (r + 3.0))
		inner.append(p * r)
		light.append(p * r * 0.8 + Vector2(-r * 0.12, -r * 0.14))
	draw_colored_polygon(outer, OUTLINE)
	draw_colored_polygon(inner, BODY)
	draw_colored_polygon(light, LIGHT.lerp(BODY, 0.45))
	for c in _craters:
		draw_circle(Vector2(c.x, c.y) * r, c.z * r + 1.5, OUTLINE)
		draw_circle(Vector2(c.x, c.y) * r, c.z * r, CRATER)
