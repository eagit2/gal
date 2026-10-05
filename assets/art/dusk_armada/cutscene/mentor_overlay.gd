extends Node2D
## Mentor cutscene look: dimmed field, a typed text box, the weapon card (stats, linked chips, combo)
## and the demo: enemies fly in and homing darts arc into them, chaining lightning to the others.
## The cutscene script sets the fields and `t`; everything here is drawn from them.

const BOX := Rect2(20, 610, 500, 120)
const CARD := Rect2(50, 170, 440, 230)
const FONT_SIZE := 10
const CHARS_PER_SECOND := 32.0
const DART_TIME := 0.35
const DART_GAP := 0.55
const INK := Color(0.05, 0.04, 0.1)
const PANEL := Color(0.1, 0.08, 0.2, 0.92)
const RIM := Color(1.0, 0.8, 0.45)

var t := 0.0
var speaker := "WINGMATE"
var line := ""
var line_start := -1.0
var card_start := -1.0
var card_title := ""
var card_rows: Array[String] = []
## [{"name", "color"}] for the linked chips.
var card_chips: Array[Dictionary] = []
var card_combo := ""
var demo_start := -1.0
var demo_scene: PackedScene
var demo_count := 3
var shooter := Vector2(270, 860)
var _targets: Array[Node2D] = []


func _process(_delta: float) -> void:
	if demo_start >= 0.0 and _targets.is_empty() and demo_scene:
		for i in demo_count:
			var target := demo_scene.instantiate() as Node2D
			add_child(target)
			_targets.append(target)
	for i in _targets.size():
		var target := _targets[i]
		var arrive := clampf((t - demo_start) / 1.0, 0.0, 1.0)
		var x := 540.0 * (i + 1) / (_targets.size() + 1)
		target.position = Vector2(x, lerpf(-40.0, 300.0 + 40.0 * (i % 2), ease(arrive, 0.4)))
		target.visible = t < _hit_time(i)
	queue_redraw()


func _hit_time(i: int) -> float:
	return demo_start + 1.0 + i * DART_GAP + DART_TIME


func _draw() -> void:
	draw_rect(Rect2(0, 0, 540, 960), Color(0.02, 0.01, 0.06, 0.45))
	_draw_demo()
	if card_start >= 0.0 and t >= card_start:
		_draw_card(clampf((t - card_start) / 0.3, 0.0, 1.0))
	if line_start >= 0.0 and t >= line_start:
		_draw_box()


func _font() -> Font:
	var theme := ThemeDB.get_project_theme()
	return theme.default_font if theme and theme.default_font else ThemeDB.fallback_font


func _text(at: Vector2, text: String, color: Color, size := FONT_SIZE, width := -1.0) -> void:
	var font := _font()
	if width > 0.0:
		draw_multiline_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, 3, INK)
		draw_multiline_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, color)
	else:
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, INK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _panel(rect: Rect2) -> void:
	draw_rect(rect.grow(3), INK)
	draw_rect(rect, PANEL)
	draw_rect(rect, RIM, false, 2.0)


func _draw_box() -> void:
	_panel(BOX)
	_text(BOX.position + Vector2(14, 22), speaker, RIM)
	var shown := line.substr(0, int((t - line_start) * CHARS_PER_SECOND))
	_text(BOX.position + Vector2(14, 48), shown, Color.WHITE, FONT_SIZE, BOX.size.x - 28)


func _draw_card(grow: float) -> void:
	var rect := Rect2(CARD.get_center() - CARD.size * grow * 0.5, CARD.size * grow)
	_panel(rect)
	if grow < 1.0:
		return
	var at := CARD.position + Vector2(18, 30)
	_text(at, card_title, RIM, 12)
	for i in card_rows.size():
		_text(at + Vector2(0, 30 + i * 20), card_rows[i], Color.WHITE)
	if card_chips.is_empty():
		return
	var y := at.y + 40 + card_rows.size() * 20
	var left := Vector2(CARD.position.x + 90, y)
	var right := Vector2(CARD.end.x - 90, y)
	var pulse := 0.6 + 0.4 * sin(t * 8.0)
	draw_line(left, right, Color(card_chips[0]["color"], pulse), 6.0)
	for i in mini(card_chips.size(), 2):
		var c: Vector2 = left if i == 0 else right
		draw_circle(c, 15, INK)
		draw_circle(c, 12, card_chips[i]["color"])
		var name: String = card_chips[i]["name"]
		_text(c + Vector2(-_font().get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x * 0.5, 32), name, Color.WHITE)
	if card_combo != "":
		var size := _font().get_string_size(card_combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		_text(Vector2(CARD.get_center().x - size.x * 0.5, y + 66), card_combo, Color(0.6, 0.85, 1.0), 12)


## Darts curve from the ship into each target in turn; each hit arcs lightning to the targets left.
func _draw_demo() -> void:
	if demo_start < 0.0:
		return
	for i in _targets.size():
		var fire := demo_start + 1.0 + i * DART_GAP
		var hit := fire + DART_TIME
		var target := _targets[i].position
		if t >= fire and t < hit:
			var k := (t - fire) / DART_TIME
			var bend := shooter + Vector2(140.0 * (1 if i % 2 == 0 else -1), -260)
			var p := shooter.lerp(bend, k).lerp(bend.lerp(target, k), k)
			draw_line(p, p + Vector2(0, 12).rotated(p.angle_to_point(target) - PI * 0.5), Color(0.75, 1, 1), 3.0)
			draw_circle(p, 4, Color(0.6, 0.95, 1))
		elif t >= hit and t < hit + 0.3:
			var fade := 1.0 - (t - hit) / 0.3
			draw_circle(target, 26 * (1.2 - fade), Color(1, 0.85, 0.4, fade))
			for j in range(i + 1, _targets.size()):
				_bolt(target, _targets[j].position, Color(0.6, 0.85, 1, fade))


func _bolt(a: Vector2, b: Vector2, color: Color) -> void:
	var points := PackedVector2Array([a])
	var normal := (b - a).orthogonal().normalized()
	for k in range(1, 6):
		points.append(a.lerp(b, k / 6.0) + normal * randf_range(-10, 10))
	points.append(b)
	draw_polyline(points, color, 2.5)
