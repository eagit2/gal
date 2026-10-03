extends Control
## Hangar menus: a ship preview with the current loadout, then Loadout (slot modules into the
## frame's linked slots), Modules (levels and AP), Shop (modules and upgrade chains) and Frames.
## Built in code from the module catalog, so new content needs only data. Keyboard, gamepad
## (focus) and touch all work; cancel goes back one menu.

const TITLE_SCENE := "res://scenes/main/title.tscn"
const SHIP_VISUAL := preload("res://assets/art/dusk_armada/player.tscn")
const SHIP_PARTS := preload("res://assets/art/dusk_armada/ship_parts.gd")

var _catalog: ModuleCatalog = preload("res://data/hangar/catalog.tres")
var _title: Label
var _credits: Label
var _list: VBoxContainer
var _detail: Label
var _back := Callable()
var _ship: Node2D
var _preview: Control


func _ready() -> void:
	_build()
	EventBus.credits_changed.connect(func(_c: int) -> void: _credits.text = "CREDITS  %d" % Hangar.credits())
	_credits.text = "CREDITS  %d" % Hangar.credits()
	_home()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back.call()


func _build() -> void:
	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.texture = HangarUI.sky()
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 28
	column.offset_right = -28
	column.offset_top = 24
	column.offset_bottom = -24
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_title = HangarUI.label("HANGAR", 24, HangarUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_title)
	_credits = HangarUI.label("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_credits)
	_preview = Control.new()
	_preview.custom_minimum_size.y = 170
	_ship = SHIP_VISUAL.instantiate()
	_preview.resized.connect(func() -> void: _ship.position = _preview.size / 2)
	column.add_child(_preview)
	_ship.scale = Vector2(3, 3)
	_preview.add_child(_ship)
	var parts := Node2D.new()
	parts.set_script(SHIP_PARTS)
	parts.set("hull", _ship.get_node("dusk_armada/Sprite"))
	_ship.get_node("dusk_armada").add_child(parts)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 5)
	scroll.add_child(_list)
	_detail = HangarUI.label("", 16)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_detail.custom_minimum_size = Vector2(0, 104)
	column.add_child(HangarUI.panel(_detail))


## Clears the list for a new menu. `back` runs on cancel.
func _page(title: String, back: Callable) -> void:
	_title.text = title
	_back = back
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


func _add(button: Button, detail: String, action: Callable) -> Button:
	button.focus_entered.connect(func() -> void: _detail.text = detail)
	button.mouse_entered.connect(func() -> void: _detail.text = detail)
	button.pressed.connect(action)
	_list.add_child(button)
	return button


func _focus(index := 0) -> void:
	var rows := _list.get_children()
	if not rows.is_empty():
		(rows[clampi(index, 0, rows.size() - 1)] as Button).grab_focus()


func _module_text(def: ModuleDef) -> String:
	var chain := ""
	for other in _catalog.modules:
		if other.requires_mastered == def.id:
			chain = "\nMaster it to unlock %s." % other.display_name
	return "%s  (%s)\n%s%s" % [def.display_name.to_upper(), HangarUI.KIND_NAMES[def.kind], def.description, chain]


func _home(focus := 0) -> void:
	_page("HANGAR", SceneRouter.go_to.bind(TITLE_SCENE))
	var frame := Hangar.frame()
	var state := Hangar.state()
	var used := range(frame.slots).filter(func(s: int) -> bool: return Loadout.in_slot(_catalog, state, s) >= 0).size()
	_add(HangarUI.row("LOADOUT", "", "%d / %d" % [used, frame.slots]), "Slot modules into your frame. Linked slots let blue support modules boost their partner.", _loadout)
	_add(HangarUI.row("MODULES", "", str((state["modules"] as Array).size())), "Your modules. Equipped modules earn AP from kills and level up. A mastered module spawns a fresh copy.", _modules)
	_add(HangarUI.row("SHOP", "", ""), "Buy modules with medal credits. Mastering a module unlocks its upgrade in the shop.", _shop)
	_add(HangarUI.row("FRAMES", "", frame.display_name.to_upper()), "Frames set how many slots and linked pairs your ship has.", _frames)
	_add(HangarUI.row("BACK"), "Back to the title screen.", SceneRouter.go_to.bind(TITLE_SCENE))
	_focus(focus)


func _loadout(focus := 0) -> void:
	var frame := Hangar.frame()
	var state := Hangar.state()
	_page("LOADOUT  %s" % frame.display_name.to_upper(), _home.bind(0))
	for slot in frame.slots:
		var index := Loadout.in_slot(_catalog, state, slot)
		var def := Loadout.def_at(_catalog, state, index)
		var partner := frame.partner(slot)
		var link := "" if partner < 0 else ("LINK %d-%d" % [mini(slot, partner) + 1, maxi(slot, partner) + 1])
		var dot := HangarUI.KIND_COLORS[def.kind] if def else Color.TRANSPARENT
		var stars := HangarUI.stars(Loadout.slot_level(_catalog, state, slot), def.max_level()) if def else ""
		var link_color := HangarUI.KIND_COLORS[1] if partner >= 0 and (Loadout.link_active(_catalog, state, slot) or Loadout.link_active(_catalog, state, partner)) else HangarUI.DIM
		var text := _module_text(def) if def else "Empty slot."
		if def and def.kind == ModuleDef.Kind.SUPPORT and not Loadout.link_active(_catalog, state, slot):
			text += "\nInactive: link it to a %s module." % ("weapon" if def.link_kind == ModuleDef.Kind.WEAPON else "non-support")
		_add(HangarUI.row("%d  %s" % [slot + 1, def.display_name.to_upper() if def else "- EMPTY -"], stars, link, dot, link_color), text, _picker.bind(slot))
	_focus(focus)


func _picker(slot: int) -> void:
	var state := Hangar.state()
	_page("SLOT %d" % (slot + 1), _loadout.bind(slot))
	_add(HangarUI.row("- EMPTY -"), "Leave this slot empty.", _equip.bind(slot, -1))
	var modules: Array = state["modules"]
	for index in modules.size():
		var def := Loadout.def_at(_catalog, state, index)
		var where := (state["equipped"] as Array).find(index)
		var right := "SLOT %d" % (where + 1) if where >= 0 and where < Hangar.frame().slots else ""
		_add(HangarUI.row(def.display_name.to_upper(), HangarUI.stars(Loadout.level_of(_catalog, state, index), def.max_level()), right, HangarUI.KIND_COLORS[def.kind], HangarUI.DIM), _module_text(def), _equip.bind(slot, index))
	_focus(maxi((state["equipped"] as Array)[slot] + 1, 0))


func _equip(slot: int, index: int) -> void:
	Hangar.equip(slot, index)
	_loadout(slot)


func _modules() -> void:
	var state := Hangar.state()
	_page("MODULES", _home.bind(1))
	var modules: Array = state["modules"]
	for index in modules.size():
		var def := Loadout.def_at(_catalog, state, index)
		var ap := int(modules[index]["ap"])
		var level := def.level_for(ap)
		var next := "MASTER" if level >= def.max_level() else "AP %d/%d" % [ap, def.ap_levels[level - 1]]
		_add(HangarUI.row(def.display_name.to_upper(), HangarUI.stars(level, def.max_level()), next, HangarUI.KIND_COLORS[def.kind], HangarUI.GOOD if level >= def.max_level() else Color.WHITE), _module_text(def), func() -> void: pass)
	_focus()


func _shop(focus := 0) -> void:
	var state := Hangar.state()
	_page("SHOP", _home.bind(2))
	for def in _catalog.modules:
		if Loadout.owns(state, def.id):
			continue
		if Loadout.in_shop(_catalog, state, def):
			var color := HangarUI.GOLD if def.cost <= Hangar.credits() else HangarUI.ROSE
			_add(HangarUI.row(def.display_name.to_upper(), "", str(def.cost), HangarUI.KIND_COLORS[def.kind], color), _module_text(def), _buy_module.bind(def))
		else:
			var req := _catalog.module(def.requires_mastered)
			_add(HangarUI.row(def.display_name.to_upper(), "", "LOCKED", HangarUI.DIM, HangarUI.DIM), "%s\nMaster %s to unlock." % [_module_text(def), req.display_name], func() -> void: pass)
	if _list.get_child_count() == 0:
		_add(HangarUI.row("SOLD OUT"), "You own every module.", _home.bind(2))
	_focus(focus)


func _buy_module(def: ModuleDef) -> void:
	var index := _list.get_children().find(get_viewport().gui_get_focus_owner())
	if Hangar.buy_module(def):
		_shop(index)
		_detail.text = "Bought %s. Equip it in LOADOUT." % def.display_name.to_upper()
	else:
		_detail.text = "Needs %d more credits. Earn medals in stages." % (def.cost - Hangar.credits())


func _frames(focus := 0) -> void:
	_page("FRAMES", _home.bind(3))
	for frame in _catalog.frames:
		var right := "IN USE" if frame == Hangar.frame() else ("USE" if Hangar.owns_frame(frame.id) else str(frame.cost))
		var color := HangarUI.GOOD if Hangar.owns_frame(frame.id) else (HangarUI.GOLD if frame.cost <= Hangar.credits() else HangarUI.ROSE)
		var text := "%s\n%s" % [frame.display_name.to_upper(), frame.description]
		_add(HangarUI.row(frame.display_name.to_upper(), "%d SLOTS" % frame.slots, right, Color.TRANSPARENT, color), text, _pick_frame.bind(frame, _catalog.frames.find(frame)))
	_focus(focus)


func _pick_frame(frame: FrameDef, index: int) -> void:
	if Hangar.owns_frame(frame.id):
		Hangar.use_frame(frame.id)
	elif not Hangar.buy_frame(frame):
		_detail.text = "Needs %d more credits." % (frame.cost - Hangar.credits())
		return
	_frames(index)
