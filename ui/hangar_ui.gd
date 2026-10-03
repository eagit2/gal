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
const CATEGORY_COLORS: Array[Color] = [Color("5fe06a"), Color("b98bff"), Color("ffd34f"), Color("4fa6ff"), Color("ffd34f"), Color("ff8f6b")]
const CATEGORY_NAMES := ["WEAPONS", "SHIELDS", "POWERS", "ENGINES", "EXTRAS", "CHIPS"]
const TIER_NAMES := ["STARTER", "COMMON", "UNCOMMON", "RARE", "EPIC"]
const TIER_COLORS: Array[Color] = [Color("9a9ab3"), Color("f4efe6"), Color("8ce6bf"), Color("6fb8ff"), Color("e58cff")]
## Placement effects in words, by stat. Lower shield_recharge is faster.
const STAT_WORDS := {&"strafe_right": "strafe right", &"strafe_left": "strafe left", &"move_speed": "speed", &"shield_recharge": "shield recharge"}
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


## Level bars: one small block per level, filled up to `level`.
static func bars(level: int, max_level: int, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in max_level:
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(18, 10)
		bar.color = color if i < level else Color(0.24, 0.22, 0.39)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
	return row


## A two-line upgrade card: name and level bars, then what the next level changes and its price.
static func upgrade_card(title: String, level: int, max_level: int, color: Color, change: String, price: String, price_color: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 84
	style(button)
	var lines := VBoxContainer.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.offset_left = 12
	lines.offset_right = -12
	lines.offset_top = 12
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_theme_constant_override("separation", 14)
	button.add_child(lines)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := label(title, 16, color)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	top.add_child(bars(level, max_level, color))
	lines.add_child(top)
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var what := label(change, 16, Color.WHITE)
	what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	what.clip_text = true
	bottom.add_child(what)
	bottom.add_child(label(price, 16, price_color, HORIZONTAL_ALIGNMENT_RIGHT))
	lines.add_child(bottom)
	return button


## "+25% strafe right, recharge 20% faster" for placement effects.
static func effect_words(effects: Array[Dictionary]) -> String:
	var words: PackedStringArray = []
	for effect in effects:
		var value: float = effect["value"]
		var name: String = STAT_WORDS.get(effect["stat"], String(effect["stat"]))
		if effect["stat"] == &"shield_recharge":
			words.append("%s %d%% faster" % [name, roundi((1.0 - value) * 100.0)])
		else:
			words.append("+%d%% %s" % [roundi((value - 1.0) * 100.0), name])
	return ", ".join(words)


## A slot box for the hangar home: mount name in the part's color, the part, its attribute levels.
static func slot_box(mount_name: String, def: PartDef, state: Dictionary) -> Button:
	var button := Button.new()
	button.size = Vector2(170, 104)
	style(button)
	var color := CATEGORY_COLORS[def.category] if def else DIM
	button.add_theme_stylebox_override("normal", box(INK, color))
	var lines := VBoxContainer.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.offset_left = 10
	lines.offset_right = -8
	lines.offset_top = 10
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_theme_constant_override("separation", 6)
	button.add_child(lines)
	lines.add_child(label(mount_name, 8, color))
	var name := label(def.display_name.to_upper() if def else "- EMPTY -", 16)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(name)
	lines.add_child(label("LV %d" % Loadout.total_levels(state, def.id) if def else "", 16, GOOD))
	return button


## A store card: the ship wearing the part (`preview` state) on the left; name, rarity, category
## price and link sockets on the right.
static func part_card(def: PartDef, preview: Dictionary, credits: int, sockets: Array[int]) -> Button:
	var card := Button.new()
	card.custom_minimum_size.y = 112
	style(card)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var ship := ship_preview(preview, 1.75, 104)
	ship.custom_minimum_size.x = 112
	row.add_child(ship)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	text.add_child(label(def.display_name.to_upper(), 16))
	text.add_theme_constant_override("separation", 8)
	var kind := HBoxContainer.new()
	kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kind.add_child(label(TIER_NAMES[def.tier], 8, TIER_COLORS[def.tier]))
	kind.add_child(label(CATEGORY_NAMES[def.category], 8, CATEGORY_COLORS[def.category]))
	text.add_child(kind)
	text.add_child(HangarCards.sockets(sockets))
	row.add_child(label(str(def.price()), 16, GOLD if def.price() <= credits else ROSE, HORIZONTAL_ALIGNMENT_RIGHT))
	return card


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
