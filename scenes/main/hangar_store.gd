class_name HangarStore
extends Control
## Hangar store: category tabs, a card per part showing your ship wearing it, and a detail view with
## Before and After previews, the look of each rank, and Buy / Rank Up / Fit. Built from the
## catalog, so new parts need only data.

signal closed

var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")
var _category := PartDef.Category.WEAPON
var _detail_part: PartDef
var _body: VBoxContainer
var _credits: Label
var _tabs: Array[Button] = []


func _ready() -> void:
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 28
	column.offset_right = -28
	column.offset_top = 24
	column.offset_bottom = -24
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(HangarUI.label("STORE", 24, HangarUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_credits = HangarUI.label("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_credits)
	var tabs := GridContainer.new()
	tabs.columns = 3
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	column.add_child(tabs)
	for category in HangarUI.CATEGORY_NAMES.size():
		var tab := Button.new()
		tab.text = HangarUI.CATEGORY_NAMES[category]
		tab.custom_minimum_size.y = 40
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 16)
		HangarUI.style(tab)
		tab.pressed.connect(_show_category.bind(category))
		tabs.add_child(tab)
		_tabs.append(tab)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 6)
	scroll.add_child(_body)
	_show_category(_category)


## Cancel: from a part's detail back to its category, else out of the store.
func back() -> void:
	if _detail_part:
		_show_category(_category, _catalog.parts.find(_detail_part))
	else:
		closed.emit()


func _clear() -> void:
	_credits.text = "SCRAP  %d" % Hangar.credits()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


func _show_category(category: int, focus_part := -1) -> void:
	_category = category as PartDef.Category
	_detail_part = null
	_clear()
	for i in _tabs.size():
		_tabs[i].add_theme_color_override("font_color", HangarUI.CATEGORY_COLORS[i] if i == category else HangarUI.DIM)
	var state := Hangar.state()
	var focus: Control = _tabs[category]
	for def in _catalog.parts:
		if def.category != category:
			continue
		var card := _card(def, state)
		_body.add_child(card)
		if _catalog.parts.find(def) == focus_part:
			focus = card
	if _body.get_child_count() == 0:
		_body.add_child(HangarUI.label("Chips arrive with combos.", 16, HangarUI.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_body.add_child(_button("BACK", closed.emit))
	focus.grab_focus.call_deferred()


## A part card: your ship wearing it on the left, name, tier, rank and price on the right.
func _card(def: PartDef, state: Dictionary) -> Button:
	var rank := Loadout.rank_of(state, def.id)
	var card := Button.new()
	card.custom_minimum_size.y = 112
	HangarUI.style(card)
	card.pressed.connect(_show_part.bind(def))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var ship := HangarUI.ship_preview(Loadout.preview(_catalog, state, def, maxi(rank, 1)), 1.75, 104)
	ship.custom_minimum_size.x = 112
	row.add_child(ship)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	text.add_child(HangarUI.label(def.display_name.to_upper(), 16))
	text.add_child(HangarUI.label(HangarUI.TIER_NAMES[def.tier], 16, HangarUI.CATEGORY_COLORS[def.category]))
	var price := Loadout.next_price(state, def)
	var status := HangarUI.stars(rank, PartDef.MAX_RANK) if rank > 0 else "NEW"
	text.add_child(HangarUI.label("%s  %s" % [status, "MAX" if price < 0 else str(price)], 16, _price_color(price)))
	return card


func _show_part(def: PartDef) -> void:
	_detail_part = def
	_clear()
	var state := Hangar.state()
	var rank := Loadout.rank_of(state, def.id)
	_body.add_child(HangarUI.label(def.display_name.to_upper(), 24, HangarUI.CATEGORY_COLORS[def.category]))
	_body.add_child(HangarUI.label("%s  %s" % [HangarUI.TIER_NAMES[def.tier], HangarUI.CATEGORY_NAMES[def.category]], 16, HangarUI.DIM))
	var compare := HBoxContainer.new()
	compare.add_theme_constant_override("separation", 8)
	_body.add_child(compare)
	var next := mini(rank + 1, PartDef.MAX_RANK)
	compare.add_child(_framed("NOW", HangarUI.ship_preview({}, 2.5, 150)))
	compare.add_child(_framed("AFTER", HangarUI.ship_preview(Loadout.preview(_catalog, state, def, next), 2.5, 150)))
	_body.add_child(HangarUI.label("RANK LOOKS", 16, HangarUI.DIM))
	var ranks := HBoxContainer.new()
	ranks.add_theme_constant_override("separation", 8)
	_body.add_child(ranks)
	for r in range(1, PartDef.MAX_RANK + 1):
		ranks.add_child(_framed("R%d" % r, HangarUI.ship_preview(Loadout.preview(_catalog, state, def, r), 2.0, 110)))
	var lines: PackedStringArray = []
	for r in PartDef.MAX_RANK:
		lines.append("%s R%d  %s" % ["★" if r < rank else "☆", r + 1, def.rank_text[r]])
	var info := HangarUI.label("\n".join(lines), 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(HangarUI.panel(info))
	var price := Loadout.next_price(state, def)
	var buy := _button("MAXED" if price < 0 else ("%s  %d" % ["BUY" if rank == 0 else "RANK UP", price]), _buy.bind(def))
	buy.disabled = price < 0
	_body.add_child(buy)
	if rank > 0 and Loadout.mount_of(state, def.id) == &"":
		_body.add_child(_button("FIT TO SHIP", _fit.bind(def)))
	_body.add_child(_button("BACK", back))
	buy.grab_focus.call_deferred()


func _buy(def: PartDef) -> void:
	if Hangar.buy_part(def):
		_show_part(def)
	else:
		_credits.text = "NEEDS %d MORE SCRAP" % (Loadout.next_price(Hangar.state(), def) - Hangar.credits())


## Fits an owned part where the preview puts it, swapping out a part of the same slot type.
func _fit(def: PartDef) -> void:
	var fitted := Loadout.preview(_catalog, Hangar.state(), def, Loadout.rank_of(Hangar.state(), def.id))
	var mount := Loadout.mount_of(fitted, def.id)
	if mount != &"":
		Hangar.place(mount, &"")
		Hangar.place(mount, def.id)
	_show_part(def)


func _framed(caption: String, content: Control) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_child(HangarUI.label(caption, 16, HangarUI.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(content)
	var panel := HangarUI.panel(box)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel


func _button(text: String, action: Callable) -> Button:
	var button := HangarUI.row(text)
	button.pressed.connect(action)
	return button


func _price_color(price: int) -> Color:
	if price < 0:
		return HangarUI.GOOD
	return HangarUI.GOLD if price <= Hangar.credits() else HangarUI.ROSE
