class_name HangarTree
extends RefCounted
## The ship's skill tree, drawn into the hangar's list as a map: the ship at the bottom, three
## branches growing up from it, forks marked OR (one closes the other), merge nodes where two
## branches meet, and capstones fed by any two nodes below them (ShipTree).

const BRANCH_COLORS := {&"offense": Color("5fe06a"), &"defense": Color("b98bff"), &"utility": Color("4fa6ff"), &"merge": Color("f2c46e"), &"capstone": Color("f2c46e")}
const OFF := Color(0.3, 0.28, 0.45)
const MAP := Vector2(484, 640)
const NODE := 48.0
const ROW_GAP := 124.0

var menu: Control  # scenes/main/hangar.gd
var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _init(owner: Control) -> void:
	menu = owner


func open(focus_node: StringName = &"") -> void:
	var state := Hangar.state()
	var ship := Hangar.ship()
	var back: Callable = menu.home.bind(ship.mounts.size() + 1)
	menu.page("%s TREE" % ship.display_name.to_upper(), back)
	menu.hide_ship()
	var map := Control.new()
	map.custom_minimum_size = MAP
	var lines := TreeLines.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.add_child(lines)
	_root(map, ship)
	var to_focus: Button = null
	for node in ship.tree:
		_connect(lines, state, ship, node)
		var button := _node(map, state, ship, node)
		if to_focus == null or node.id == focus_node:
			to_focus = button
	for node in ship.tree:
		var partner := ship.node(node.excludes) if node.excludes != &"" else null
		if partner and String(node.id) < String(partner.id):
			var at := (_spot(node) + _spot(partner)) / 2.0
			if node.requires.size() == 1 and node.requires == partner.requires:
				at.y += ROW_GAP / 2.0  # where the fork splits
			_badge(map, at, "OR", HangarUI.ROSE)
	lines.queue_redraw()
	menu.add_body(map)
	menu.add(HangarUI.row("< BACK"), "Back to the hangar.", back)
	if to_focus:
		to_focus.grab_focus()
	else:
		menu.focus()


## Center of a node on the map.
func _spot(node: TreeNodeDef) -> Vector2:
	return Vector2(40.0 + node.column * (MAP.x - 80.0) / 5.0, MAP.y - 40.0 - node.row * ROW_GAP)


func _root(map: Control, ship: ShipDef) -> void:
	var hull := TextureRect.new()
	var frame := AtlasTexture.new()
	frame.atlas = ship.sprite
	frame.region = Rect2(0, 0, ship.sprite.get_width() / 2.0, ship.sprite.get_height())
	hull.texture = frame
	hull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hull.size = Vector2(34, 36) * 1.5
	hull.position = Vector2(MAP.x / 2.0, MAP.y - 40.0) - hull.size / 2.0
	hull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.add_child(hull)


## Lines from the nodes `node` hangs from: lit when both ends are owned, gold when it can be bought.
func _connect(lines: TreeLines, state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> void:
	var gate := ShipTree.gate(_catalog, state, node)
	var owned := ShipTree.rank(state, ship, node) > 0
	if node.requires.is_empty():
		lines.elbows.append({"from": Vector2(MAP.x / 2.0, MAP.y - 40.0), "to": _spot(node), "color": BRANCH_COLORS[node.branch]})
		return
	if node.needs > 0:  # capstone: fed by a bar across the row below
		var bar_y := _spot(node).y + ROW_GAP / 2.0
		var lit := gate == ShipTree.Gate.OPEN or owned
		lines.bars.append({"from": Vector2(_spot(node).x, _spot(node).y), "to": Vector2(_spot(node).x, bar_y), "color": BRANCH_COLORS[node.branch] if lit else OFF})
		for id in node.requires:
			var parent := ship.node(id)
			var from := _spot(parent)
			lines.bars.append({"from": Vector2(from.x, bar_y), "to": from, "color": BRANCH_COLORS[parent.branch] if ShipTree.rank(state, ship, parent) > 0 else OFF})
			lines.bars.append({"from": Vector2(from.x, bar_y), "to": Vector2(_spot(node).x, bar_y), "color": OFF})
		return
	for id in node.requires:
		var parent := ship.node(id)
		var lit := ShipTree.rank(state, ship, parent) > 0 and gate != ShipTree.Gate.CLOSED
		lines.elbows.append({"from": _spot(parent), "to": _spot(node), "color": BRANCH_COLORS[node.branch] if lit else OFF})


func _node(map: Control, state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> Button:
	var gate := ShipTree.gate(_catalog, state, node)
	var rank := ShipTree.rank(state, ship, node)
	var color: Color = BRANCH_COLORS[node.branch]
	var button := Button.new()
	HangarUI.style(button)
	var size := NODE * (0.8 if node.branch == &"merge" else 1.0)
	button.size = Vector2(size, size)
	button.position = _spot(node) - button.size / 2.0
	button.pivot_offset = button.size / 2.0
	var fill := color if rank > 0 else HangarUI.INK
	var border := OFF if gate == ShipTree.Gate.CLOSED or (gate == ShipTree.Gate.NEEDS_NODE and rank == 0) else color
	var normal := HangarUI.box(fill, HangarUI.GOLD if gate == ShipTree.Gate.OPEN and rank == 0 else border, 3)
	if node.branch == &"capstone":
		normal.set_corner_radius_all(int(size / 2.0))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	if node.branch == &"merge":
		button.rotation = PI / 4.0
	var mark := "X" if gate == ShipTree.Gate.CLOSED else ("%d/%d" % [rank, node.max_rank] if node.max_rank > 1 else ("O" if node.socket_category >= 0 else ""))
	var mark_label := HangarUI.label(mark, 8, Color(0.08, 0.1, 0.24) if rank > 0 else border, HORIZONTAL_ALIGNMENT_CENTER)
	mark_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	mark_label.rotation = -button.rotation
	mark_label.pivot_offset = button.size / 2.0
	button.add_child(mark_label)
	button.focus_entered.connect(menu.say.bind(_text(state, ship, node)))
	button.mouse_entered.connect(menu.say.bind(_text(state, ship, node)))
	button.pressed.connect(_buy.bind(node))
	map.add_child(button)
	var name := HangarUI.label(node.display_name.to_upper(), 8, HangarUI.DIM if gate == ShipTree.Gate.CLOSED else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.size = Vector2(80, 30)
	name.position = _spot(node) + Vector2(-40, NODE / 2.0 + 6)
	map.add_child(name)
	return button


func _badge(map: Control, at: Vector2, text: String, color: Color) -> void:
	var badge := Panel.new()
	badge.add_theme_stylebox_override("panel", HangarUI.box(HangarUI.INK, color))
	badge.size = Vector2(28, 18)
	badge.position = at - badge.size / 2.0
	var label := HangarUI.label(text, 8, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(label)
	map.add_child(badge)


## What one rank does, its price or state, what it needs or closes, and the next change.
func _text(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> String:
	var rank := ShipTree.rank(state, ship, node)
	var text := "%s  %d / %d\n%s." % [node.display_name.to_upper(), rank, node.max_rank, node.text]
	match ShipTree.gate(_catalog, state, node):
		ShipTree.Gate.NEEDS_NODE:
			text += "\nNeeds %s." % ShipTree.needs_text(ship, node)
		ShipTree.Gate.CLOSED:
			text += "\nClosed: you took %s." % ship.node(node.excludes).display_name.to_upper()
		ShipTree.Gate.OPEN:
			text += "\n%d scrap." % ShipTree.price(state, ship, node)
			if node.excludes != &"":
				text += " Closes %s." % ship.node(node.excludes).display_name.to_upper()
	return text


func _buy(node: TreeNodeDef) -> void:
	var state := Hangar.state()
	match ShipTree.gate(_catalog, state, node):
		ShipTree.Gate.MAXED:
			menu.say("Maxed.")
		ShipTree.Gate.NEEDS_NODE:
			menu.say("Needs %s first." % ShipTree.needs_text(Hangar.ship(), node))
		ShipTree.Gate.CLOSED:
			menu.say("Closed: you took %s." % Hangar.ship().node(node.excludes).display_name.to_upper())
		_:
			if not Hangar.buy_node(node):
				menu.say("Needs %d more scrap." % (ShipTree.price(state, Hangar.ship(), node) - Hangar.credits()))
			else:
				open(node.id)
