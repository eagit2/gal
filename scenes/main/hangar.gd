extends Control
## Hangar menus. Home shows the ship and its slots; picking a slot opens its categories, then the
## parts of one category, then the part's attributes to upgrade and fit (HangarParts). Also the
## rotating store, the blueprint tree (HangarBlueprint) and pilots. Built in code from the catalog,
## so new content needs only data. Keyboard, gamepad (focus) and touch all work; cancel goes back.

const TITLE_SCENE := "res://scenes/main/title.tscn"
const MOUNT_NAMES := {&"nose": "NOSE", &"left": "LEFT", &"rear": "REAR", &"right": "RIGHT", &"hull": "HULL"}

var catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")
var parts := HangarParts.new(self)
var blueprint := HangarBlueprint.new(self)
var _title: Label
var _credits: Label
var _list: VBoxContainer
var _detail: Label
var _back := Callable()
var _preview_box: Control


func _ready() -> void:
	_build()
	EventBus.credits_changed.connect(func(_c: int) -> void: _credits.text = "SCRAP  %d" % Hangar.credits())
	_credits.text = "SCRAP  %d" % Hangar.credits()
	home()


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
	_preview_box = Control.new()
	_preview_box.custom_minimum_size.y = 170
	column.add_child(_preview_box)
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


## Shows the ship with `state` (empty = the saved loadout) in the big preview, or the blueprint.
func show_ship(state: Dictionary, as_blueprint := false) -> void:
	for child in _preview_box.get_children():
		child.queue_free()
	var ship := HangarUI.blueprint(3.0, 170) if as_blueprint else HangarUI.ship_preview(state, 3.0, 170)
	ship.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_box.add_child(ship)


## Clears the list for a new menu. `back` runs on cancel.
func page(title: String, back: Callable, as_blueprint := false) -> void:
	_title.text = title
	_back = back
	_detail.text = ""
	show_ship({}, as_blueprint)
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


## Adds a row: `detail` shows in the bottom panel and `preview` in the ship view while it has focus.
func add(button: Button, detail: String, action: Callable, preview := {}) -> Button:
	var show := func() -> void:
		_detail.text = detail
		if not preview.is_empty():
			show_ship(preview)
	button.focus_entered.connect(show)
	button.mouse_entered.connect(show)
	button.pressed.connect(action)
	_list.add_child(button)
	return button


func focus(index := 0) -> void:
	var rows := _list.get_children()
	if not rows.is_empty():
		(rows[clampi(index, 0, rows.size() - 1)] as Control).grab_focus()


func row_count() -> int:
	return _list.get_child_count()


func say(text: String) -> void:
	_detail.text = text


func home(focus_row := 0) -> void:
	page("HANGAR", SceneRouter.go_to.bind(TITLE_SCENE))
	var ship := Hangar.ship()
	var state := Hangar.state()
	for mount in ship.mounts:
		var def := Loadout.part_at(catalog, state, mount)
		var dot := HangarUI.CATEGORY_COLORS[def.category] if def else Color.TRANSPARENT
		var name := def.display_name.to_upper() if def else "- EMPTY -"
		var detail := parts.describe(def, mount) if def else "Empty. Pick it to fit a part."
		add(HangarUI.row("%s  %s" % [MOUNT_NAMES[mount], name], "", HangarUI.levels_short(state, def) if def else "", dot), detail, parts.slot.bind(mount))
	var stock := (state["stock"] as Array).size()
	add(HangarUI.row("STORE", "", "%d FOR SALE" % stock), "New parts for scrap. The stock changes after every run.", parts.store)
	add(HangarUI.row("BLUEPRINT"), "The %s tree. Rarer parts on a mount open deeper nodes there." % ship.display_name.to_upper(), blueprint.open)
	add(HangarUI.row("PILOT", "", Hangar.pilot().display_name.to_upper(), Color.TRANSPARENT, Hangar.pilot().color), "Pick your pilot. Each one brings an active power.", _pilots)
	add(HangarUI.row("BACK"), "Back to the title screen.", SceneRouter.go_to.bind(TITLE_SCENE))
	focus(focus_row)


func _pilots(focus_row := 0) -> void:
	page("PILOTS", home.bind(Hangar.ship().mounts.size() + 2))
	for pilot in catalog.pilots:
		var owned := Hangar.owns_pilot(pilot.id)
		var right := "FLYING" if pilot == Hangar.pilot() else ("FLY" if owned else str(pilot.cost))
		var color := HangarUI.GOOD if owned else (HangarUI.GOLD if pilot.cost <= Hangar.credits() else HangarUI.ROSE)
		var text := "%s: %s\n%s  (%ds recharge)\n%s" % [pilot.display_name.to_upper(), pilot.power_name, pilot.power_text, roundi(pilot.cooldown), pilot.bio]
		add(HangarUI.row(pilot.display_name.to_upper(), pilot.power_name, right, pilot.color, color), text, _pick_pilot.bind(pilot, catalog.pilots.find(pilot)))
	focus(focus_row)


func _pick_pilot(pilot: PilotDef, index: int) -> void:
	if not Hangar.choose_pilot(pilot):
		say("Needs %d more scrap." % (pilot.cost - Hangar.credits()))
		return
	_pilots(index)
	say("%s is flying. Power: SHIFT, gamepad B, or a two-finger tap." % pilot.display_name.to_upper())
