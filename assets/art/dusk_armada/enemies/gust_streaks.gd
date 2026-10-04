extends Node2D
## Wind lines that sweep across the screen: faint while a gust winds up, strong while it blows.

var direction := 1.0
var strength := 0.3
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for i in 14:
		var y := fposmod(i * 71.0 + sin(i * 3.1) * 40.0, 900.0) + 50.0
		var speed := 500.0 + (i % 4) * 120.0
		var x := fposmod(_t * speed * direction + i * 133.0, 700.0) - 80.0
		var length := 60.0 + (i % 3) * 30.0
		var color := Color(0.8, 0.95, 1.0, strength * (0.5 + 0.5 * sin(i * 1.7 + _t * 6.0)))
		var tip := Vector2(x + length * direction, y)
		draw_line(Vector2(x, y), tip, color, 2.0)
		draw_line(tip, tip + Vector2(-8.0 * direction, -6.0), color, 2.0)
