class_name HangarUI
extends RefCounted
## Widgets and Dusk Armada colors for the hangar menus. Fonts come from the project theme
## (Press Start 2P: use sizes in multiples of 8).

const GOLD := Color(0.95, 0.77, 0.43)
const ROSE := Color(0.85, 0.52, 0.55)
const INK := Color(0.07, 0.08, 0.17, 0.88)
const DIM := Color(0.6, 0.6, 0.7)
const GOOD := Color(0.55, 0.9, 0.75)
## By PartDef.Category: weapon, shield, power, engine, extra, chip.
const CATEGORY_COLORS: Array[Color] = [Color("5fe06a"), Color("b98bff"), Color("ffd34f"), Color("4fa6ff"), Color("4fa6ff"), Color("ff8f6b")]
const CATEGORY_NAMES := ["WEAPONS", "SHIELDS", "POWERS", "ENGINES", "EXTRAS", "CHIPS"]
const TIER_NAMES := ["STARTER", "COMMON", "UNCOMMON", "RARE", "EPIC"]
const SHIP_VISUAL := preload("res://assets/art/dusk_armada/player.tscn")
const SHIP_PARTS := preload("res://assets/art/dusk_armada/ship_parts.gd")
const ROW_HEIGHT := 44


static func label(text: String, size: int, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1))
	l.add_theme_constant_override("outline_size", 4)
	return l


## A menu row: left text (with an optional colored dot), middle and right columns.
static func row(left: String, mid := "", right := "", dot := Color.TRANSPARENT, right_color := GOLD) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = ROW_HEIGHT
	style(button)
	var parts := HBoxContainer.new()
	parts.name = "Parts"
	parts.set_anchors_preset(Control.PRESET_FULL_RECT)
	parts.offset_left = 12
	parts.offset_right = -12
	parts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parts.add_theme_constant_override("separation", 10)
	button.add_child(parts)
	if dot.a > 0:
		var swatch := ColorRect.new()
		swatch.color = dot
		swatch.custom_minimum_size = Vector2(8, 8)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		parts.add_child(swatch)
	var name_label := label(left, 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts.add_child(name_label)
	parts.add_child(label(mid, 16, GOOD))
	var right_label := label(right, 16, right_color, HORIZONTAL_ALIGNMENT_RIGHT)
	right_label.custom_minimum_size.x = 112
	parts.add_child(right_label)
	return button


static func stars(level: int, max_level: int) -> String:
	return "★".repeat(mini(level, max_level)) + "☆".repeat(maxi(max_level - level, 0)) + ("+%d" % (level - max_level) if level > max_level else "")


## A box showing the ship with its parts, centered. `state` empty = the saved loadout.
static func ship_preview(state: Dictionary, zoom: float, height: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size.y = height
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ship: Node2D = SHIP_VISUAL.instantiate()
	ship.scale = Vector2(zoom, zoom)
	var parts := Node2D.new()
	parts.set_script(SHIP_PARTS)
	parts.set("hull", ship.get_node("dusk_armada/Sprite"))
	parts.set("preview", state)
	ship.get_node("dusk_armada").add_child(parts)
	holder.add_child(ship)
	holder.resized.connect(func() -> void: ship.position = holder.size / 2)
	return holder


static func panel(content: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var b := box(INK, ROSE.darkened(0.3))
	b.content_margin_left = 14
	b.content_margin_right = 14
	b.content_margin_top = 8
	b.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", b)
	p.add_child(content)
	return p


static func style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", box(INK, Color(0.3, 0.28, 0.45)))
	button.add_theme_stylebox_override("hover", box(INK.lightened(0.08), ROSE))
	button.add_theme_stylebox_override("pressed", box(INK.lightened(0.15), GOLD))
	button.add_theme_stylebox_override("disabled", box(INK.darkened(0.3), Color(0.2, 0.2, 0.3)))
	button.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD, 3))


static func box(fill: Color, border: Color, width := 2) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(3)
	return b


## Dusk sky: night blue at the top fading through slate violet to dusty rose (no dithering).
static func sky() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.08, 0.1, 0.24), Color(0.26, 0.22, 0.4), Color(0.6, 0.38, 0.45)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2(0, 1)
	texture.width = 4
	texture.height = 256
	return texture
