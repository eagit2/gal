extends Control
## Hangar menus. SHIPS comes first (locked ships show what unlocks them); a ship opens its home,
## with the ship and its slots. Picking a slot opens its categories, then the parts of one category,
## then the part's attributes to upgrade and fit (HangarParts). Also the rotating store, the ship
## tree (HangarTree) and pilots. Built in code from the catalog,
## so new content needs only data. Keyboard, gamepad (focus) and touch all work; cancel goes back.

const TITLE_SCENE := "res://scenes/main/title.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
## Home layout: the area holding the ship and its slot boxes, and each box's top-left corner.
const SLOT_AREA := Vector2(484, 384)
const SLOT_SPOTS := {&"nose": Vector2(157, 0), &"left": Vector2(0, 134), &"right": Vector2(314, 134), &"rear": Vector2(157, 280)}
const MOUNT_NAMES := {&"nose": "NOSE", &"left": "LEFT", &"rear": "REAR", &"right": "RIGHT", &"hull": "HULL"}

var catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")
var parts := HangarParts.new(self)
var tree := HangarTree.new(self)
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
	ships()


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


## Shows the ship with `state` (empty = the saved loadout) in the big preview.
func show_ship(state: Dictionary) -> void:
	for child in _preview_box.get_children():
		child.queue_free()
	var ship := HangarUI.ship_preview(state, 3.0, 170)
	ship.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_box.add_child(ship)


## Clears the list for a new menu. `back` runs on cancel.
func page(title: String, back: Callable) -> void:
	_title.text = title
	_back = back
	_detail.text = ""
	_preview_box.custom_minimum_size.y = 170
	show_ship({})
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


## Hides the ship view for pages with their own picture (ships, the tree).
func hide_ship() -> void:
	_preview_box.custom_minimum_size.y = 0
	for child in _preview_box.get_children():
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


## Adds any control to the page body (the ship tree's columns).
func add_body(control: Control) -> void:
	_list.add_child(control)


func focus(index := 0) -> void:
	var rows := _list.get_children()
	if not rows.is_empty():
		(rows[clampi(index, 0, rows.size() - 1)] as Control).grab_focus()


func row_count() -> int:
	return _list.get_child_count()


func say(text: String) -> void:
	_detail.text = text


## Every ship: open ones fly (and open their hangar), locked ones say what unlocks them.
func ships(focus_row := -1) -> void:
	page("SHIPS", SceneRouter.go_to.bind(TITLE_SCENE))
	hide_ship()
	var state := Hangar.state()
	for ship in catalog.ships:
		var open := Loadout.unlocked(state, ship)
		var card := HangarCards.ship_card(ship, open, ship == Hangar.ship())
		var text := "%s. %s" % [ship.display_name.to_upper(), ship.description] if open else "Locked. Unlock: %s." % ship.unlock_text.to_lower()
		add(card, text, _fly.bind(ship))
		if focus_row < 0 and ship == Hangar.ship():
			focus_row = row_count() - 1
	add(HangarUI.row("< BACK"), "Back to the title screen.", SceneRouter.go_to.bind(TITLE_SCENE))
	focus(focus_row)


func _fly(ship: ShipDef) -> void:
	if not Hangar.choose_ship(ship):
		say("Locked. Unlock: %s." % ship.unlock_text.to_lower())
		return
	home()


func home(focus_row := 0) -> void:
	page("%s HANGAR" % Hangar.ship().display_name.to_upper(), ships.bind(-1))
	var ship := Hangar.ship()
	var state := Hangar.state()
	_slot_boxes(ship, state)
	var stock := (state["stock"] as Array).size()
	add(HangarUI.row("STORE", "", "%d FOR SALE" % stock), "New parts for scrap. The stock changes after every run.", parts.store)
	var owned := 0
	var total := 0
	for node in ship.tree:
		owned += ShipTree.rank(state, ship, node)
		total += node.max_rank
	add(HangarUI.row("SHIP TREE", "", "%d / %d" % [owned, total]), "The %s's own skill tree." % ship.display_name.to_upper(), tree.open)
	add(HangarUI.row("PILOT", "", Hangar.pilot().display_name.to_upper(), Color.TRANSPARENT, Hangar.pilot().color), "Pick your pilot. Each one brings an active power.", _pilots)
	var run: Dictionary = SaveManager.data["run"]
	var stage := "STAGE %d" % (int(run.get("stage", 0)) + 1) if not run.is_empty() else "STAGE 1"
	add(HangarUI.row("< SHIPS"), "Pick another ship.", ships.bind(-1))
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	add_body(gap)
	add(HangarUI.row("RESTART LEVEL", "", stage), "Fly %s again with this loadout." % stage, _restart)
	var boxes := _preview_box.get_children().filter(func(c: Node) -> bool: return c is Button and not c.is_queued_for_deletion())
	if focus_row < boxes.size():
		(boxes[focus_row] as Button).grab_focus()
	else:
		focus(focus_row - boxes.size())


## Starts the saved stage (or a new run on the slot's difficulty) with the current loadout.
func _restart() -> void:
	SaveManager.save()
	GameState.resume_requested = SaveManager.has_run()
	GameState.difficulty_id = StringName(SaveManager.data["last_difficulty"])
	StyleDirector.set_stage_style(&"")
	SceneRouter.go_to(GAME_SCENE)


## The ship with a box per slot around it (nose above, sides beside, rear below). Each box shows
## the part and its attribute levels and opens the slot's menu.
func _slot_boxes(ship: ShipDef, state: Dictionary) -> void:
	_preview_box.custom_minimum_size.y = SLOT_AREA.y
	for mount in ship.mounts:
		var def := Loadout.part_at(catalog, state, mount)
		var box := HangarUI.slot_box(MOUNT_NAMES[mount], def, state)
		box.position = SLOT_SPOTS.get(mount, Vector2.ZERO)
		box.focus_entered.connect(say.bind(parts.describe(def, mount) if def else "Empty. Pick it to fit a part."))
		box.mouse_entered.connect(say.bind(parts.describe(def, mount) if def else "Empty. Pick it to fit a part."))
		box.pressed.connect(parts.slot.bind(mount))
		_preview_box.add_child(box)


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
	say("%s is flying. The power fires on its own." % pilot.display_name.to_upper())
