class_name HangarTree
extends RefCounted
## The ship's skill tree, drawn into the hangar's list: three branches side by side (offense,
## defense, utility), each a column of nodes from the top down. Nodes belong to the ship; each
## needs a rank in the node above it (ShipTree).

const BRANCH_COLORS := {&"offense": Color("5fe06a"), &"defense": Color("b98bff"), &"utility": Color("4fa6ff")}

var menu: Control  # scenes/main/hangar.gd
var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _init(owner: Control) -> void:
	menu = owner


func open(focus_node: StringName = &"") -> void:
	var state := Hangar.state()
	var ship := Hangar.ship()
	menu.page("%s TREE" % ship.display_name.to_upper(), menu.home.bind(ship.mounts.size() + 1))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 6)
	menu.add_body(columns)
	var to_focus: Button = null
	for branch in ShipTree.BRANCHES:
		var color: Color = BRANCH_COLORS[branch]
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 0)
		columns.add_child(column)
		column.add_child(HangarUI.label(String(branch).to_upper(), 16, color, HORIZONTAL_ALIGNMENT_CENTER))
		for node in ShipTree.branch(ship, branch):
			var rank := ShipTree.rank(state, ship, node)
			var link := ColorRect.new()
			link.custom_minimum_size = Vector2(4, 14)
			link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			link.color = color if rank > 0 else Color(0.3, 0.28, 0.45)
			column.add_child(link)
			var card := HangarUI.node_card(node.display_name.to_upper(), rank, node.max_rank, color, _status(state, ship, node), _status_color(state, ship, node))
			card.focus_entered.connect(menu.say.bind(_text(state, ship, node)))
			card.mouse_entered.connect(menu.say.bind(_text(state, ship, node)))
			card.pressed.connect(_buy.bind(node))
			column.add_child(card)
			if to_focus == null or node.id == focus_node:
				to_focus = card
	var back := HangarUI.row("BACK")
	menu.add(back, "Back to the hangar.", menu.home.bind(ship.mounts.size() + 1))
	if to_focus:
		to_focus.grab_focus()


func _status(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> String:
	match ShipTree.gate(_catalog, state, node):
		ShipTree.Gate.MAXED:
			return "MAX"
		ShipTree.Gate.NEEDS_NODE:
			return "LOCKED"
	return str(ShipTree.price(state, ship, node))


func _status_color(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> Color:
	match ShipTree.gate(_catalog, state, node):
		ShipTree.Gate.MAXED:
			return HangarUI.GOOD
		ShipTree.Gate.NEEDS_NODE:
			return HangarUI.DIM
	return HangarUI.GOLD if ShipTree.price(state, ship, node) <= Hangar.credits() else HangarUI.ROSE


## What one rank does, what the next rank changes in real numbers, and what it needs.
func _text(state: Dictionary, ship: ShipDef, node: TreeNodeDef) -> String:
	var rank := ShipTree.rank(state, ship, node)
	var text := "%s  rank %d / %d\n%s per rank." % [node.display_name.to_upper(), rank, node.max_rank, node.text]
	match ShipTree.gate(_catalog, state, node):
		ShipTree.Gate.NEEDS_NODE:
			text += "\nNeeds a rank in %s first." % ship.node(node.requires).display_name.to_upper()
		ShipTree.Gate.OPEN:
			var after := state.duplicate(true)
			ShipTree.buy(_catalog, after, node)
			text += "\nNext: %s" % StatWords.change(node.effects, _stats(state), _stats(after))
	return text


func _stats(state: Dictionary) -> Dictionary:
	return UpgradeSystem.compute(Loadout.effects(_catalog, state))


func _buy(node: TreeNodeDef) -> void:
	var gate := ShipTree.gate(_catalog, Hangar.state(), node)
	if gate == ShipTree.Gate.MAXED:
		menu.say("Maxed.")
	elif gate == ShipTree.Gate.NEEDS_NODE:
		menu.say("Needs a rank in %s first." % Hangar.ship().node(node.requires).display_name.to_upper())
	elif not Hangar.buy_node(node):
		menu.say("Needs %d more scrap." % (ShipTree.price(Hangar.state(), Hangar.ship(), node) - Hangar.credits()))
	else:
		open(node.id)
