extends Control
## Hangar: spend medal credits on permanent ship upgrades between runs. Built in code from
## the hangar tree data so new nodes need only data. Keyboard, gamepad (focus) and touch all work.

var _tree: HangarTree = preload("res://data/hangar/hangar_tree.tres")
const BRANCH_NAMES := ["HULL", "WEAPONS", "SYSTEMS"]
const GOLD := Color(0.95, 0.77, 0.43)
const ROSE := Color(0.85, 0.52, 0.55)
const INK := Color(0.07, 0.08, 0.17, 0.88)
const DIM := Color(0.6, 0.6, 0.7)
const OWNED := Color(0.55, 0.9, 0.75)
const ROW_SIZE := Vector2(480, 46)

var _rows := {}  # node id -> Button
var _credits: Label
var _detail: Label
var _focused: HangarNodeDef


func _ready() -> void:
	_build()
	_refresh()
	EventBus.credits_changed.connect(func(_c: int) -> void: _refresh())
	(_rows.values()[0] as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.go_to("res://scenes/main/title.tscn")


func _build() -> void:
	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.texture = _sky_texture()
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 30
	column.offset_right = -30
	column.offset_top = 36
	column.offset_bottom = -30
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(_label("HANGAR", 40, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_credits = _label("", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_credits)
	for branch in BRANCH_NAMES.size():
		var header := _label(BRANCH_NAMES[branch], 18, ROSE, HORIZONTAL_ALIGNMENT_LEFT)
		header.custom_minimum_size.y = 34
		header.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		column.add_child(header)
		for node: HangarNodeDef in _tree.nodes:
			if node.branch == branch:
				column.add_child(_make_row(node))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	_detail = _label("", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(0, 72)
	column.add_child(_panel(_detail))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)
	buttons.add_child(_action_button("BACK", func() -> void: SceneRouter.go_to("res://scenes/main/title.tscn")))


func _make_row(node: HangarNodeDef) -> Button:
	var row := Button.new()
	row.custom_minimum_size = ROW_SIZE
	_style_button(row)
	var parts := HBoxContainer.new()
	parts.name = "Parts"
	parts.set_anchors_preset(Control.PRESET_FULL_RECT)
	parts.offset_left = 14
	parts.offset_right = -14
	parts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for part_name in ["Name", "Pips", "Cost"]:
		var part := _label("", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		part.name = part_name
		part.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		part.size_flags_vertical = Control.SIZE_EXPAND_FILL
		parts.add_child(part)
	parts.get_node("Name").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts.get_node("Cost").custom_minimum_size.x = 70
	parts.get_node("Cost").horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(parts)
	row.focus_entered.connect(_show_detail.bind(node))
	row.mouse_entered.connect(_show_detail.bind(node))
	row.pressed.connect(_on_row_pressed.bind(node))
	_rows[node.id] = row
	return row


func _on_row_pressed(node: HangarNodeDef) -> void:
	var row: Button = _rows[node.id]
	if Hangar.buy(node):
		_refresh()
		row.pivot_offset = row.size / 2
		var tween := create_tween()
		tween.tween_property(row, "scale", Vector2(1.04, 1.04), 0.06)
		tween.tween_property(row, "scale", Vector2.ONE, 0.12)
	else:
		var tween := create_tween()
		tween.tween_property(row, "position:x", row.position.x + 6, 0.04)
		tween.tween_property(row, "position:x", row.position.x, 0.08)


func _refresh() -> void:
	_credits.text = "CREDITS  %d" % Hangar.credits()
	for node: HangarNodeDef in _tree.nodes:
		var row: Button = _rows[node.id]
		var rank := Hangar.rank_of(node.id)
		var cost := HangarRules.next_cost(node, Hangar.ranks())
		var unlocked := HangarRules.is_unlocked(node, Hangar.ranks())
		var name_label: Label = row.get_node("Parts/Name")
		var pips: Label = row.get_node("Parts/Pips")
		var cost_label: Label = row.get_node("Parts/Cost")
		name_label.text = node.display_name.to_upper()
		pips.text = "◆".repeat(rank) + "◇".repeat(node.max_rank() - rank)
		pips.modulate = OWNED if rank > 0 else DIM
		if cost < 0:
			cost_label.text = "MAX"
			cost_label.modulate = OWNED
		elif not unlocked:
			cost_label.text = "LOCKED"
			cost_label.modulate = DIM
		else:
			cost_label.text = str(cost)
			cost_label.modulate = GOLD if cost <= Hangar.credits() else ROSE
		name_label.modulate = Color.WHITE if unlocked else DIM
	if _focused:
		_show_detail(_focused)


func _show_detail(node: HangarNodeDef) -> void:
	_focused = node
	var rank := Hangar.rank_of(node.id)
	var cost := HangarRules.next_cost(node, Hangar.ranks())
	var status := "Rank %d / %d.  " % [rank, node.max_rank()]
	if cost < 0:
		status += "Fully upgraded."
	elif not HangarRules.is_unlocked(node, Hangar.ranks()):
		var names: Array[String] = []
		for id in node.requires:
			names.append(_tree.find(id).display_name)
		status += "Needs %s." % ", ".join(names)
	elif cost > Hangar.credits():
		status += "Needs %d more credits. Earn medals in stages." % (cost - Hangar.credits())
	else:
		status += "Press fire to buy for %d." % cost
	_detail.text = "%s\n%s\n%s" % [node.display_name.to_upper(), node.description, status]


func _label(text: String, size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1))
	label.add_theme_constant_override("outline_size", 4)
	return label


func _panel(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := _box(INK, ROSE.darkened(0.3))
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", box)
	panel.add_child(content)
	return panel


func _action_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(170, 52)
	button.add_theme_font_size_override("font_size", 22)
	_style_button(button)
	button.pressed.connect(action)
	return button


func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(INK, Color(0.3, 0.28, 0.45)))
	button.add_theme_stylebox_override("hover", _box(INK.lightened(0.08), ROSE))
	button.add_theme_stylebox_override("pressed", _box(INK.lightened(0.15), GOLD))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), GOLD, 3))


func _box(fill: Color, border: Color, width := 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(3)
	return box


## Dusk sky: night blue at the top fading through slate violet to dusty rose (no dithering).
func _sky_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.08, 0.1, 0.24), Color(0.26, 0.22, 0.4), Color(0.6, 0.38, 0.45)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	texture.width = 4
	texture.height = 256
	return texture
