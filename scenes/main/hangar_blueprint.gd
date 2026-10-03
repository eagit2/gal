class_name HangarBlueprint
extends RefCounted
## The ship's blueprint tree, drawn into the hangar's list. Nodes sit on the mount whose part they
## boost; the fitted part's rarity decides how deep that mount's nodes go (ShipTree).

const GATE_COLORS := {ShipTree.Gate.OPEN: HangarUI.GOLD, ShipTree.Gate.MAXED: HangarUI.GOOD}

var menu: Control  # scenes/main/hangar.gd
var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _init(owner: Control) -> void:
	menu = owner


func open(focus_row := 0) -> void:
	var state := Hangar.state()
	var ship := Hangar.ship()
	menu.page("%s BLUEPRINT" % ship.display_name.to_upper(), menu.home.bind(ship.mounts.size() + 1), true)
	var order: Array[StringName] = ship.mounts.duplicate()
	order.append(&"hull")
	for mount in order:
		_header(state, mount)
		for node in ship.tree:
			if node.mount != mount:
				continue
			var rank := ShipTree.rank(state, ship, node)
			var gate := ShipTree.gate(_catalog, state, node)
			var dot := HangarUI.GOLD if rank > 0 and ShipTree.powered(_catalog, state, node) else HangarUI.TIER_COLORS[node.min_tier]
			var row := HangarUI.row(node.display_name.to_upper(), "%d/%d" % [rank, node.max_rank], _right(state, ship, node, gate), dot, GATE_COLORS.get(gate, HangarUI.DIM))
			menu.add(row, _text(state, node, gate), _buy.bind(node, menu.row_count()))
	menu.focus(focus_row if focus_row > 0 else 1)


## A row naming the mount and the part (with its rarity) that powers its nodes. Not focusable.
func _header(state: Dictionary, mount: StringName) -> void:
	var part := Loadout.part_at(_catalog, state, mount) if mount != &"hull" else null
	var right: String = HangarUI.TIER_NAMES[part.tier] if part else ""
	var row := HangarUI.row("%s  %s" % [menu.MOUNT_NAMES[mount], part.display_name.to_upper() if part else ("" if mount == &"hull" else "- EMPTY -")], "", right, Color.TRANSPARENT, HangarUI.TIER_COLORS[part.tier] if part else HangarUI.DIM)
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.flat = true
	menu.add(row, "", func() -> void: pass)


func _right(state: Dictionary, ship: ShipDef, node: TreeNodeDef, gate: ShipTree.Gate) -> String:
	match gate:
		ShipTree.Gate.MAXED:
			return "MAX"
		ShipTree.Gate.NEEDS_NODE:
			return "LOCKED"
		ShipTree.Gate.NEEDS_PART:
			return HangarUI.TIER_NAMES[node.min_tier]
	return str(ShipTree.price(state, ship, node))


func _text(state: Dictionary, node: TreeNodeDef, gate: ShipTree.Gate) -> String:
	var text := "%s: %s per rank." % [node.display_name.to_upper(), node.text]
	var part := Loadout.part_at(_catalog, state, node.mount) if node.mount != &"hull" else null
	var fitted := "%s (%s)" % [part.display_name, HangarUI.TIER_NAMES[part.tier]] if part else "nothing"
	if node.mount != &"hull" and not ShipTree.powered(_catalog, state, node):
		var tier: String = HangarUI.TIER_NAMES[node.min_tier]
		text += "\nNeeds %s %s or rarer part on the %s. Fitted: %s.%s" % ["an" if tier[0] in "AEIOU" else "a", tier, menu.MOUNT_NAMES[node.mount], fitted, " Your ranks are dark until then." if ShipTree.rank(state, Hangar.ship(), node) > 0 else ""]
	elif gate == ShipTree.Gate.NEEDS_NODE:
		text += "\nNeeds a rank in %s first." % Hangar.ship().node(node.requires).display_name.to_upper()
	return text


func _buy(node: TreeNodeDef, row: int) -> void:
	var gate := ShipTree.gate(_catalog, Hangar.state(), node)
	if gate != ShipTree.Gate.OPEN:
		return
	if not Hangar.buy_node(node):
		menu.say("Needs %d more scrap." % (ShipTree.price(Hangar.state(), Hangar.ship(), node) - Hangar.credits()))
		return
	open(row)
