class_name HangarCards
extends RefCounted
## Larger hangar widgets: link sockets, the category dropdown card, ship cards and tree nodes.
## Colors and basic widgets come from HangarUI.

const SOCKET_GOLD := Color("f2c46e")
const TREE_GREEN := Color("8ce6bf")
const LOCKED := Color(0.3, 0.28, 0.45)


## A row of link sockets (Loadout.sockets): gold circles, a bar joining linked pairs, and green
## ones for sockets the ship tree adds. `fills`: the chip color in each socket (transparent = empty).
static func sockets(groups: Array[int], size := 18, fills: Array[Color] = []) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	var index := 0
	for group in groups:
		var cluster := HBoxContainer.new()
		cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cluster.add_theme_constant_override("separation", 0)
		row.add_child(cluster)
		var color := TREE_GREEN if group == 0 else SOCKET_GOLD
		for i in maxi(group, 1):
			var fill: Color = fills[index] if index < fills.size() else Color.TRANSPARENT
			index += 1
			if i > 0:
				var bar := ColorRect.new()
				bar.color = SOCKET_GOLD
				bar.custom_minimum_size = Vector2(10, 4)
				bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				cluster.add_child(bar)
			cluster.add_child(_circle(color, size, fill))
	return row


static func _circle(color: Color, size: int, fill := Color.TRANSPARENT) -> Panel:
	var circle := Panel.new()
	circle.custom_minimum_size = Vector2(size, size)
	circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := HangarUI.box(fill if fill.a > 0 else HangarUI.INK, color, 3)
	b.set_corner_radius_all(size / 2)
	circle.add_theme_stylebox_override("panel", b)
	return circle


## A part row that opens in place when highlighted: the row, then each attribute's level bars and
## final number, then the part's sockets. `stats`: [[name, level, max, value text]].
static func drop_card(row: Button, stats: Array, groups: Array[int], fills: Array[Color], color: Color) -> Button:
	var details := VBoxContainer.new()
	details.name = "Details"
	details.visible = false
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.position = Vector2(30, HangarUI.ROW_HEIGHT)
	details.add_theme_constant_override("separation", 8)
	for s: Array in stats:
		details.add_child(_stat_line(s[0], HangarUI.bars(s[1], s[2], color), HangarUI.label(s[3], 16), color))
	details.add_child(_stat_line("LINKS", sockets(groups, 18, fills), Control.new(), SOCKET_GOLD))
	row.add_child(details)
	var parts: Control = row.get_node("Parts")
	parts.anchor_bottom = 0.0
	parts.offset_bottom = HangarUI.ROW_HEIGHT
	return row


## Puts a tappable tag at the right end of a row (EQUIPPED / UNEQUIPPED) that runs `action`.
static func status_tag(row: Button, text: String, color: Color, action: Callable) -> Button:
	var tag := Button.new()
	tag.text = text
	tag.focus_mode = Control.FOCUS_NONE
	tag.custom_minimum_size = Vector2(150, HangarUI.ROW_HEIGHT - 12)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", color)
	tag.add_theme_color_override("font_hover_color", HangarUI.GOLD)
	tag.add_theme_stylebox_override("normal", HangarUI.box(HangarUI.INK.darkened(0.2), color.darkened(0.3)))
	tag.add_theme_stylebox_override("hover", HangarUI.box(HangarUI.INK.lightened(0.1), HangarUI.GOLD))
	tag.add_theme_stylebox_override("pressed", HangarUI.box(HangarUI.INK.lightened(0.15), HangarUI.GOLD))
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.pressed.connect(action)
	var parts: HBoxContainer = row.get_node("Parts")
	parts.get_child(parts.get_child_count() - 1).queue_free()
	parts.add_child(tag)
	return tag


## One color per linked pair on a part, in socket order.
const PAIR_COLORS: Array[Color] = [Color("f2c46e"), Color("6fd6c8"), Color("ef7fa6"), Color("a98bff")]


## Marks a row as half of linked pair `pair`: both rows share the pair's border and tint, and a
## thick bar of the same color bridges the middle of the gap to the row below (`down`).
static func link_line(row: Button, pair: int, down: bool) -> void:
	var color := PAIR_COLORS[pair % PAIR_COLORS.size()]
	row.add_theme_stylebox_override("normal", HangarUI.box(HangarUI.INK.lerp(color, 0.14), color, 3))
	row.add_theme_stylebox_override("hover", HangarUI.box(HangarUI.INK.lerp(color, 0.24), color, 3))
	if not down:
		return
	var bar := ColorRect.new()
	bar.color = color
	bar.z_index = 1
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.offset_left = -13
	bar.offset_right = 13
	bar.offset_top = HangarUI.ROW_HEIGHT - 14
	bar.offset_bottom = HangarUI.ROW_HEIGHT + 19  # into the next row, across the 5 px spacing
	row.add_child(bar)


static func _stat_line(title: String, middle: Control, right: Control, color: Color) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 12)
	var name := HangarUI.label(title, 8, color)
	name.custom_minimum_size.x = 112
	line.add_child(name)
	middle.custom_minimum_size.x = 110
	line.add_child(middle)
	line.add_child(right)
	return line


## Opens or closes a drop card, growing the row to fit.
static func set_open(card: Button, open: bool) -> void:
	var details: Control = card.get_node("Details")
	details.visible = open
	card.custom_minimum_size.y = HangarUI.ROW_HEIGHT + (details.get_combined_minimum_size().y + 12 if open else 0.0)


## A ship on the SHIPS page: its hull, name, and FLYING / FLY or what unlocks it.
static func ship_card(ship: ShipDef, unlocked: bool, flying: bool) -> Button:
	var card := Button.new()
	card.custom_minimum_size.y = 180
	HangarUI.style(card)
	card.add_theme_stylebox_override("normal", HangarUI.box(HangarUI.INK, SOCKET_GOLD if flying else LOCKED))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 20
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 24)
	card.add_child(row)
	var hull := TextureRect.new()
	var frame := AtlasTexture.new()
	frame.atlas = ship.sprite
	frame.region = Rect2(0, 0, ship.sprite.get_width() / 2.0, ship.sprite.get_height())
	hull.texture = frame
	hull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hull.custom_minimum_size = Vector2(136, 144)
	hull.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		hull.modulate = Color(0.35, 0.35, 0.4)
	row.add_child(hull)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 14)
	row.add_child(text)
	text.add_child(HangarUI.label(ship.display_name.to_upper(), 24, Color.WHITE if unlocked else HangarUI.DIM))
	var tag := "FLYING >" if flying else ("FLY >" if unlocked else "LOCKED: " + ship.unlock_text)
	var tag_label := HangarUI.label(tag, 8 if not unlocked else 16, HangarUI.GOOD if unlocked else HangarUI.DIM)
	tag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag_label.custom_minimum_size.x = 220
	text.add_child(tag_label)
	return card


## A chip in the store: its color, name, what it does, copies owned and price.
static func chip_card(chip: ChipDef, owned: int, credits: int) -> Button:
	var card := Button.new()
	card.custom_minimum_size.y = 112
	HangarUI.style(card)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 40
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 40)
	card.add_child(row)
	row.add_child(_circle(SOCKET_GOLD, 48, chip.color))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 8)
	row.add_child(text)
	text.add_child(HangarUI.label("%s CHIP" % chip.display_name.to_upper(), 16))
	var what := HangarUI.label(chip.text, 8, chip.color)
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(what)
	text.add_child(HangarUI.label("OWNED %d" % owned if owned > 0 else "CHIP", 8, HangarUI.DIM))
	row.add_child(HangarUI.label(str(chip.price), 16, HangarUI.GOLD if chip.price <= credits else HangarUI.ROSE, HORIZONTAL_ALIGNMENT_RIGHT))
	return card
