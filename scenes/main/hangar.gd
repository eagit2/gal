extends Control
## Hangar menus: a ship preview with the current loadout, then Pilot (active powers), Loadout (fit
## parts to the ship's mounts; where a part sits changes what it does) and Store (HangarStore).
## Built in code from the catalog, so new content needs only data. Keyboard, gamepad (focus) and
## touch all work; cancel goes back one menu.

const TITLE_SCENE := "res://scenes/main/title.tscn"
const MOUNT_NAMES := {&"nose": "NOSE", &"left": "LEFT", &"rear": "REAR", &"right": "RIGHT"}
## Placement effects in words, by stat. Lower shield_recharge is faster.
const STAT_WORDS := {&"strafe_right": "strafe right", &"strafe_left": "strafe left", &"move_speed": "speed", &"shield_recharge": "shield recharge"}

var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")
var _column: VBoxContainer
var _title: Label
var _credits: Label
var _list: VBoxContainer
var _detail: Label
var _back := Callable()
var _preview_box: Control
var _store: HangarStore


func _ready() -> void:
	_build()
	EventBus.credits_changed.connect(func(_c: int) -> void: _credits.text = "SCRAP  %d" % Hangar.credits())
	_credits.text = "SCRAP  %d" % Hangar.credits()
	_home()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _store:
			_store.back()
		else:
			_back.call()


func _build() -> void:
	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.texture = HangarUI.sky()
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)
	_column = VBoxContainer.new()
	_column.set_anchors_preset(Control.PRESET_FULL_RECT)
	_column.offset_left = 28
	_column.offset_right = -28
	_column.offset_top = 24
	_column.offset_bottom = -24
	_column.add_theme_constant_override("separation", 6)
	add_child(_column)
	_title = HangarUI.label("HANGAR", 24, HangarUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_column.add_child(_title)
	_credits = HangarUI.label("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_column.add_child(_credits)
	_preview_box = Control.new()
	_preview_box.custom_minimum_size.y = 170
	_column.add_child(_preview_box)
	_show_ship({})
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 5)
	scroll.add_child(_list)
	_detail = HangarUI.label("", 16)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_detail.custom_minimum_size = Vector2(0, 104)
	_column.add_child(HangarUI.panel(_detail))


## Shows the ship with `state` (empty = the saved loadout) in the big preview.
func _show_ship(state: Dictionary) -> void:
	for child in _preview_box.get_children():
		child.queue_free()
	var ship := HangarUI.ship_preview(state, 3.0, 170)
	ship.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_box.add_child(ship)


## Clears the list for a new menu. `back` runs on cancel.
func _page(title: String, back: Callable) -> void:
	_title.text = title
	_back = back
	_show_ship({})
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


func _add(button: Button, detail: String, action: Callable, preview := {}) -> Button:
	var show := func() -> void:
		_detail.text = detail
		if not preview.is_empty():
			_show_ship(preview)
	button.focus_entered.connect(show)
	button.mouse_entered.connect(show)
	button.pressed.connect(action)
	_list.add_child(button)
	return button


func _focus(index := 0) -> void:
	var rows := _list.get_children()
	if not rows.is_empty():
		(rows[clampi(index, 0, rows.size() - 1)] as Button).grab_focus()


func _home(focus := 0) -> void:
	_page("HANGAR", SceneRouter.go_to.bind(TITLE_SCENE))
	var ship := Hangar.ship()
	var fitted := ship.mounts.filter(func(m: StringName) -> bool: return Loadout.part_at(_catalog, Hangar.state(), m) != null).size()
	_add(HangarUI.row("PILOT", "", Hangar.pilot().display_name.to_upper(), Color.TRANSPARENT, Hangar.pilot().color), "Pick your pilot. Each one brings an active power.", _pilots)
	_add(HangarUI.row("LOADOUT", "", "%d / %d" % [fitted, ship.mounts.size()]), "Fit parts to your ship. The weapon sits on the nose; the left, rear and right mounts take a shield, a power and a bonus part, and where each sits changes what it does.", _loadout)
	_add(HangarUI.row("STORE"), "Buy parts and ranks with scrap. Every card shows the part on your ship.", _open_store)
	_add(HangarUI.row("BACK"), "Back to the title screen.", SceneRouter.go_to.bind(TITLE_SCENE))
	_focus(focus)


func _loadout(focus := 0) -> void:
	var ship := Hangar.ship()
	var state := Hangar.state()
	_page("LOADOUT  %s" % ship.display_name.to_upper(), _home.bind(1))
	for mount in ship.mounts:
		var def := Loadout.part_at(_catalog, state, mount)
		var dot := HangarUI.CATEGORY_COLORS[def.category] if def else Color.TRANSPARENT
		var stars := HangarUI.stars(Loadout.rank_of(state, def.id), PartDef.MAX_RANK) if def else ""
		var text := _part_text(def, Loadout.rank_of(state, def.id), mount) if def else "Empty mount."
		_add(HangarUI.row("%s  %s" % [MOUNT_NAMES[mount], def.display_name.to_upper() if def else "- EMPTY -"], stars, "", dot), text, _picker.bind(mount))
	_focus(focus)


func _picker(mount: StringName) -> void:
	var state := Hangar.state()
	var ship := Hangar.ship()
	_page("%s MOUNT" % MOUNT_NAMES[mount], _loadout.bind(ship.mounts.find(mount)))
	var current := Loadout.part_at(_catalog, state, mount)
	var empty := state.duplicate(true)
	empty["mounts"][String(mount)] = ""
	_add(HangarUI.row("- EMPTY -"), "Leave this mount empty.", _place.bind(mount, &""), empty)
	var focus := 0
	for def in _catalog.parts:
		var rank := Loadout.rank_of(state, def.id)
		if rank == 0 or not ship.accepts(mount, def):
			continue
		var after := state.duplicate(true)
		var fits := def == current or Loadout.can_place(_catalog, after, mount, def)
		var where := Loadout.mount_of(state, def.id)
		var right: String = MOUNT_NAMES[where] if where != &"" else ("" if fits else "SLOT FULL")
		if fits:
			Loadout.place(_catalog, after, mount, def.id)
		if def == current:
			focus = _list.get_child_count()
		_add(HangarUI.row(def.display_name.to_upper(), HangarUI.stars(rank, PartDef.MAX_RANK), right, HangarUI.CATEGORY_COLORS[def.category], HangarUI.DIM), _part_text(def, rank, mount), _place.bind(mount, def.id), after)
	_focus(focus)


func _place(mount: StringName, id: StringName) -> void:
	if not Hangar.place(mount, id):
		_detail.text = "Your ship has no free %s slot. Empty the mount that holds one first." % String(_catalog.part(id).slot()).to_upper()
		return
	_loadout(Hangar.ship().mounts.find(mount))


## Name, category, what its ranks do, and what it gets from `mount`.
func _part_text(def: PartDef, rank: int, mount: StringName) -> String:
	var text := "%s  (%s)\n%s" % [def.display_name.to_upper(), HangarUI.CATEGORY_NAMES[def.category], ". ".join(def.rank_text.slice(0, maxi(rank, 1)))]
	var placed := _catalog.placement_effects(def, mount)
	if not placed.is_empty():
		text += "\nOn %s: %s." % [MOUNT_NAMES[mount], effect_words(placed)]
	return text


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


func _open_store() -> void:
	_column.visible = false
	_store = HangarStore.new()
	_store.set_anchors_preset(Control.PRESET_FULL_RECT)
	_store.closed.connect(_close_store)
	add_child(_store)


func _close_store() -> void:
	_store.queue_free()
	_store = null
	_column.visible = true
	_home(2)


func _pilots(focus := 0) -> void:
	_page("PILOTS", _home.bind(0))
	for pilot in _catalog.pilots:
		var owned := Hangar.owns_pilot(pilot.id)
		var right := "FLYING" if pilot == Hangar.pilot() else ("FLY" if owned else str(pilot.cost))
		var color := HangarUI.GOOD if owned else (HangarUI.GOLD if pilot.cost <= Hangar.credits() else HangarUI.ROSE)
		var text := "%s: %s\n%s  (%ds recharge)\n%s" % [pilot.display_name.to_upper(), pilot.power_name, pilot.power_text, roundi(pilot.cooldown), pilot.bio]
		_add(HangarUI.row(pilot.display_name.to_upper(), pilot.power_name, right, pilot.color, color), text, _pick_pilot.bind(pilot, _catalog.pilots.find(pilot)))
	_focus(focus)


func _pick_pilot(pilot: PilotDef, index: int) -> void:
	if not Hangar.choose_pilot(pilot):
		_detail.text = "Needs %d more scrap." % (pilot.cost - Hangar.credits())
		return
	_pilots(index)
	_detail.text = "%s is flying. Power: SHIFT, gamepad B, or a two-finger tap." % pilot.display_name.to_upper()
