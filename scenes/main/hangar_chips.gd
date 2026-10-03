class_name HangarChips
extends RefCounted
## The chip screen for one part: its link sockets, each showing its chip. Picking a socket lists the
## chips owned with free copies; two chips in a linked pair that match a LinkComboDef combo.

var menu: Control  # scenes/main/hangar.gd
var parts: RefCounted  # scenes/main/hangar_parts.gd
var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _init(owner: Control, part_menus: RefCounted) -> void:
	menu = owner
	parts = part_menus


## Socket fill colors for `def` (transparent where a socket is empty).
func fills(def: PartDef) -> Array[Color]:
	var result: Array[Color] = []
	for id in Loadout.chips_in(_catalog, Hangar.state(), def):
		var chip := _catalog.chip(StringName(id))
		result.append(chip.color if chip else Color.TRANSPARENT)
	return result


## Lists the part's sockets; `back` returns to the part.
func open(def: PartDef, back: Callable, focus_row := 0) -> void:
	var state := Hangar.state()
	menu.page("%s  LINKS" % def.display_name.to_upper(), back)
	var list := Loadout.chips_in(_catalog, state, def)
	var pairs := Loadout.linked_pairs(Loadout.sockets(_catalog, state, def))
	for i in list.size():
		var chip := _catalog.chip(StringName(list[i]))
		var name := chip.display_name.to_upper() if chip else "EMPTY"
		menu.add(HangarUI.row("SOCKET %d%s" % [i + 1, _link_mark(pairs, i)], "", name + " >", chip.color if chip else HangarUI.DIM),
			chip.text + "." if chip else "Pick a chip for this socket.", pick.bind(def, i, back))
	for combo in Loadout.part_combos(_catalog, state, def):
		menu.add(HangarUI.row("COMBO  " + combo.display_name.to_upper(), "", "", HangarCards.SOCKET_GOLD, HangarUI.GOLD), combo.text + ".", func() -> void: pass)
	menu.add(HangarUI.row("< BACK"), "", back)
	menu.focus(focus_row)


## Chips that can go in socket `index`.
func pick(def: PartDef, index: int, back: Callable) -> void:
	var state := Hangar.state()
	var reopen := open.bind(def, back, index)
	menu.page("SOCKET %d" % (index + 1), reopen)
	var current := Loadout.chips_in(_catalog, state, def)[index]
	var any := false
	for chip: ChipDef in _catalog.chips:
		var free := Loadout.chips_free(state, chip.id)
		if free <= 0 and current != String(chip.id):
			continue
		any = true
		var right := "IN" if current == String(chip.id) else "x%d" % free
		menu.add(HangarUI.row(chip.display_name.to_upper(), "", right, chip.color), chip.text + ".", _put.bind(def, index, chip.id, reopen))
	if not any:
		menu.add(HangarUI.row("NO CHIPS", "", "", Color.TRANSPARENT, HangarUI.DIM), "Buy chips in the STORE.", reopen)
	if current != "":
		menu.add(HangarUI.row("EMPTY SOCKET"), "Take the chip out.", _put.bind(def, index, &"", reopen))
	menu.add(HangarUI.row("< BACK"), "", reopen)
	menu.focus()


func _put(def: PartDef, index: int, chip: StringName, reopen: Callable) -> void:
	Hangar.set_chip(def, index, chip)
	reopen.call()
	var combos := Loadout.part_combos(_catalog, Hangar.state(), def)
	if chip != &"" and not combos.is_empty():
		menu.say("Combo active: %s." % combos.back().display_name.to_upper())


## "LINK n" marks both sockets of the n-th linked pair.
func _link_mark(pairs: Array[Vector2i], i: int) -> String:
	for k in pairs.size():
		if pairs[k].x == i or pairs[k].y == i:
			return "  LINK %d" % (k + 1)
	return ""
