extends Node2D
## Drawn player shots with no sprite sheet: flak pellets (hot sparks), the Rail Spike beam (a wide
## white-hot slug with a violet glow), Scrap Cannon balls (a riveted lump of junk) and shrapnel
## (jagged flakes). Drawn facing up; the projectile turns it.

enum Kind { PELLET, RAIL, SCRAP, SHRAPNEL }

@export var kind := Kind.PELLET
@export var color := Color(1.0, 0.7, 0.3)
## Pixels: pellet / scrap radius, rail width.
@export var size := 4.0
## Rail length in pixels.
@export var length := 140.0

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if kind == Kind.RAIL:
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.PELLET:
			draw_line(Vector2(0, 2), Vector2(0, 12), Color(color, 0.45), size)
			draw_circle(Vector2.ZERO, size, color)
			draw_circle(Vector2.ZERO, size * 0.5, Color(1, 1, 0.85))
		Kind.RAIL:
			var flicker := 0.85 + 0.15 * sin(_t * 40.0)
			var half := size / 2.0
			draw_rect(Rect2(-half - 6.0, -length / 2.0, size + 12.0, length), Color(color, 0.18 * flicker))
			draw_rect(Rect2(-half, -length / 2.0, size, length), Color(color, 0.55 * flicker))
			draw_rect(Rect2(-half * 0.45, -length / 2.0, size * 0.45, length), Color(0.95, 0.9, 1.0, flicker))
			draw_colored_polygon(PackedVector2Array([Vector2(-half, -length / 2.0), Vector2(0, -length / 2.0 - 18.0), Vector2(half, -length / 2.0)]), Color(0.95, 0.9, 1.0, flicker))
		Kind.SCRAP:
			var outline := Color(0.12, 0.1, 0.12)
			var lump := PackedVector2Array()
			for i in 9:
				var r := size * (0.86 + 0.14 * sin(i * 2.7))
				lump.append(Vector2.from_angle(TAU * i / 9.0) * r)
			draw_colored_polygon(lump, outline)
			var inner := PackedVector2Array()
			for p in lump:
				inner.append(p * 0.84)
			draw_colored_polygon(inner, color)
			draw_line(Vector2(-size * 0.5, -size * 0.2), Vector2(size * 0.4, size * 0.3), color.darkened(0.35), 2.0)
			for p in [Vector2(-size * 0.35, size * 0.3), Vector2(size * 0.3, -size * 0.35), Vector2(0, 0)]:
				draw_circle(p, 2.0, color.lightened(0.45))
		Kind.SHRAPNEL:
			var flake := PackedVector2Array([Vector2(0, -size * 1.4), Vector2(size, size * 0.6), Vector2(-size * 0.8, size)])
			draw_colored_polygon(flake, color)
			draw_polyline(flake + PackedVector2Array([flake[0]]), color.lightened(0.5), 1.0)
