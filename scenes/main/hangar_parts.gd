class_name HangarParts
extends RefCounted
## Hangar part menus, drawn into the hangar's list: a slot's categories, the owned parts of a
## category (the highlighted one opens in place with its attributes and sockets, and an
## EQUIPPED / UNEQUIPPED tag toggles it), a part's attributes and link sockets (HangarChips), and
## the rotating store.

var menu: Control  # scenes/main/hangar.gd
var chips: HangarChips
var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")
var _open_card: Button


func _init(owner: Control) -> void:
	menu = owner
	chips = HangarChips.new(owner, self)


## A slot: the categories it takes. The nose takes weapons only, so it goes straight to them.
func slot(mount: StringName, focus_row := -1) -> void:
	if mount == &"nose":
		category(mount, PartDef.Category.WEAPON)
		return
	var state := Hangar.state()
	var current := Loadout.part_at(_catalog, state, mount)
	menu.page("%s SLOT" % menu.MOUNT_NAMES[mount], menu.home.bind(_mount_row(mount)))
	for cat in PartDef.MENU_CATEGORIES:
		var all := _catalog.parts.filter(func(p: PartDef) -> bool: return p.category == cat)
		var owned := all.filter(func(p: PartDef) -> bool: return Loadout.owns(state, p.id))
		menu.add(HangarUI.row(HangarUI.CATEGORY_NAMES[cat], "", "%d OWNED >" % owned.size(), HangarUI.CATEGORY_COLORS[cat]), describe(current, mount), category.bind(mount, cat))
	menu.add(HangarUI.row("< BACK"), describe(current, mount), menu.home.bind(_mount_row(mount)))
	menu.say(describe(current, mount) if current else "Empty slot.")
	if focus_row < 0:
		focus_row = PartDef.MENU_CATEGORIES.find(current.category) if current else 0
	menu.focus(maxi(focus_row, 0))


## A category's owned parts for `mount`. The highlighted one opens in place; selecting it opens
## the part. Its EQUIPPED / UNEQUIPPED tag (or the E key) equips or removes it on `mount`.
func category(mount: StringName, cat: int, focus_part: PartDef = null) -> void:
	var state := Hangar.state()
	var back: Callable = menu.home.bind(_mount_row(mount)) if mount == &"nose" else slot.bind(mount, PartDef.MENU_CATEGORIES.find(cat))
	menu.page("%s  %s" % [menu.MOUNT_NAMES[mount], HangarUI.CATEGORY_NAMES[cat]], back)
	_open_card = null
	var list := _catalog.parts.filter(func(p: PartDef) -> bool: return p.category == cat and Loadout.owns(state, p.id))
	var to_open: Button = null
	for def: PartDef in list:
		var here := Loadout.mount_of(state, def.id) == mount
		var row := HangarUI.row(def.display_name.to_upper(), "", "", HangarUI.TIER_COLORS[def.tier])
		var card := HangarCards.drop_card(row, _final_stats(state, mount, def), Loadout.sockets(_catalog, state, def), chips.fills(def), HangarUI.CATEGORY_COLORS[def.category])
		var toggle := _toggle.bind(mount, cat, def)
		HangarCards.status_tag(card, "EQUIPPED" if here else "UNEQUIPPED", HangarUI.GOOD if here else HangarUI.DIM, toggle)
		menu.add(card, describe(def, mount), part.bind(mount, def, category.bind(mount, cat, def)), _fitted(state, mount, def))
		card.focus_entered.connect(_open.bind(card))
		card.mouse_entered.connect(_open.bind(card))
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
				toggle.call())
		if to_open == null or def == focus_part or (focus_part == null and here):
			to_open = card
	if list.is_empty():
		menu.add(HangarUI.row("NONE OWNED"), "Buy parts in the STORE.", back)
	menu.add(HangarUI.row("< BACK"), "", back)
	if to_open:
		to_open.grab_focus()
	else:
		menu.focus()


## Equips `def` on `mount` (moving it from another mount), or takes it off if it is already there.
func _toggle(mount: StringName, cat: int, def: PartDef) -> void:
	var state := Hangar.state().duplicate(true)
	if Loadout.mount_of(state, def.id) == mount:
		state["mounts"][String(mount)] = ""
	elif not _force_place(state, mount, def.id):
		menu.say("That part can't go on the %s." % menu.MOUNT_NAMES[mount])
		return
	Hangar.set_mounts(state["mounts"])
	category(mount, cat, def)


## Attribute rows for a drop card: name, level, max and the stat it reaches with the part fitted.
func _final_stats(state: Dictionary, mount: StringName, def: PartDef) -> Array:
	var stats := _stats(_fitted(state, mount, def))
	var rows := []
	for a in def.attributes:
		var stat: StringName = a["effects"][0]["stat"]
		rows.append([a["name"], Loadout.level(state, def.id, a["id"]), int(a["max"]), StatWords.value(stat, stats[stat], def.weapon)])
	return rows


## Opens a part card in place, closing the last one.
func _open(card: Button) -> void:
	if _open_card == card:
		return
	if is_instance_valid(_open_card):
		HangarCards.set_open(_open_card, false)
	_open_card = card
	HangarCards.set_open(card, true)


## A part: its attributes with an upgrade per level, its link sockets, then fit, buy or back.
func part(mount: StringName, def: PartDef, back: Callable, focus_row := 0) -> void:
	var state := Hangar.state()
	menu.page(def.display_name.to_upper(), back)
	var owned := Loadout.owns(state, def.id)
	var summary := describe(def, mount)
	var where := Loadout.mount_of(state, def.id)
	var status := "EQUIPPED ON %s" % menu.MOUNT_NAMES[where] if where != &"" else ("NOT EQUIPPED" if owned else "NOT OWNED")
	menu.add_body(HangarUI.label(status, 16, HangarUI.GOOD if where != &"" else HangarUI.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var now := _stats(_fitted(state, mount, def))
	for a in def.attributes:
		var lv := Loadout.level(state, def.id, a["id"])
		var price := Loadout.upgrade_price(state, def, a["id"])
		var maxed := lv >= int(a["max"])
		var after := _fitted(state, mount, def)
		if not maxed:
			after["parts"][String(def.id)][String(a["id"])] = lv + 1
		var change := StatWords.change(a["effects"], now, _stats(after), def.weapon)
		var right := "MAX" if maxed else ("%d" % price if owned else "")
		var color := HangarUI.GOOD if maxed else (HangarUI.GOLD if price <= Hangar.credits() else HangarUI.ROSE)
		var text := "%s  level %d / %d\n%s.\n%s" % [a["name"], lv, int(a["max"]), a["text"], "Buy the part first." if not owned else ("Maxed." if maxed else "Next level: " + change)]
		menu.add(HangarUI.upgrade_card(a["name"], lv, int(a["max"]), HangarUI.CATEGORY_COLORS[def.category], change, right, color), text, _upgrade.bind(mount, def, a["id"], back))
	var links := HangarUI.row("LINKS", "", ">" if owned else "")
	var sockets := HangarCards.sockets(Loadout.sockets(_catalog, state, def), 22, chips.fills(def))
	sockets.position = Vector2(140, 11)
	links.add_child(sockets)
	var reopen := part.bind(mount, def, back, def.attributes.size())
	menu.add(links, "Chips go in link sockets; two chips in linked sockets can combo.", chips.open.bind(def, reopen) if owned else func() -> void: menu.say("Buy the part first."))
	for combo in Loadout.part_combos(_catalog, state, def):
		menu.add(HangarUI.row("COMBO  " + combo.display_name.to_upper(), "", "", HangarCards.SOCKET_GOLD, HangarUI.GOLD), combo.text + ".", func() -> void: pass)
	if HangarStock.in_stock(state, def.id) and not owned:
		menu.add(HangarUI.row("BUY", "", str(def.price()), Color.TRANSPARENT, HangarUI.GOLD if def.price() <= Hangar.credits() else HangarUI.ROSE), summary, _buy.bind(mount, def, back), _fitted(state, mount, def))
	elif not owned:
		menu.add(HangarUI.row("NOT IN STOCK", "", "", Color.TRANSPARENT, HangarUI.DIM), "Not in the store right now. The stock changes after every run.", back)
	menu.add(HangarUI.row("< BACK"), summary, back)
	menu.show_ship(_fitted(state, mount, def))
	menu.focus(focus_row)
	menu.say(summary)


## The store: the parts for sale this run, each card showing your ship wearing it, and a reroll.
func store(focus_row := 0) -> void:
	var state := Hangar.state()
	menu.page("STORE", menu.home.bind(Hangar.ship().mounts.size()))
	for id: String in state["stock"]:
		var chip := _catalog.chip(StringName(id))
		if chip:
			menu.add(HangarCards.chip_card(chip, int(state["chips"].get(id, 0)), Hangar.credits()), "%s chip. %s." % [chip.display_name.to_upper(), chip.text], _buy_chip.bind(chip))
			continue
		var def := _catalog.part(StringName(id))
		var mount := _best_mount(state, def)
		menu.add(HangarUI.part_card(def, Loadout.preview(_catalog, state, def), Hangar.credits(), Loadout.sockets(_catalog, state, def)), describe(def, mount), part.bind(mount, def, store.bind(menu.row_count())))
	if (state["stock"] as Array).is_empty():
		menu.add(HangarUI.row("SOLD OUT"), "You own every part. New ones come with combos.", menu.home)
	menu.add(HangarUI.row("REROLL", "", str(HangarStock.REROLL_COST)), "Swap the stock for new parts now instead of after the next run.", _reroll)
	menu.add(HangarUI.row("< BACK"), "Back to the hangar.", menu.home.bind(Hangar.ship().mounts.size()))
	menu.focus(focus_row)


## Rarity, category, what it does, and what `mount` adds.
func describe(def: PartDef, mount: StringName) -> String:
	if def == null:
		return ""
	var text := "%s %s. %s" % [HangarUI.TIER_NAMES[def.tier], HangarUI.CATEGORY_NAMES[def.category].to_lower().trim_suffix("s"), def.text]
	var placed := _catalog.placement_effects(def, mount)
	if not placed.is_empty():
		text += "\nOn %s: %s." % [menu.MOUNT_NAMES[mount], HangarUI.effect_words(placed)]
	return text


func _stats(state: Dictionary) -> Dictionary:
	return UpgradeSystem.compute(Loadout.effects(_catalog, state))


## The loadout with `def` on `mount` (swapping out a part of its slot type elsewhere), for previews.
func _fitted(state: Dictionary, mount: StringName, def: PartDef) -> Dictionary:
	var copy := state.duplicate(true)
	if not Loadout.owns(copy, def.id):
		copy["parts"][String(def.id)] = {}
	_force_place(copy, mount, def.id)
	return copy


## Places the part, first emptying mounts whose parts fill the same slot type until it fits.
func _force_place(state: Dictionary, mount: StringName, id: StringName) -> bool:
	if id != &"" and not Loadout.can_place(_catalog, state, mount, _catalog.part(id)):
		for other in Loadout.ship_of(_catalog, state).mounts:
			var p := Loadout.part_at(_catalog, state, other)
			if other != mount and p and p.slot() == _catalog.part(id).slot():
				state["mounts"][String(other)] = ""
				if Loadout.can_place(_catalog, state, mount, _catalog.part(id)):
					break
	return Loadout.place(_catalog, state, mount, id)


func _upgrade(mount: StringName, def: PartDef, attr: StringName, back: Callable) -> void:
	var row := def.attributes.find(def.attribute(attr))
	if not Loadout.owns(Hangar.state(), def.id):
		menu.say("Buy the part first.")
	elif Loadout.upgrade_price(Hangar.state(), def, attr) < 0:
		menu.say("Maxed.")
	elif not Hangar.upgrade(def, attr):
		menu.say("Needs %d more scrap." % (Loadout.upgrade_price(Hangar.state(), def, attr) - Hangar.credits()))
	else:
		part(mount, def, back, row)


func _buy(mount: StringName, def: PartDef, back: Callable) -> void:
	if not Hangar.buy_part(def):
		menu.say("Needs %d more scrap." % (def.price() - Hangar.credits()))
		return
	part(mount, def, back)
	menu.say("Bought. Equip it from the %s slot." % menu.MOUNT_NAMES[mount])


func _buy_chip(chip: ChipDef) -> void:
	if not Hangar.buy_chip(chip):
		menu.say("Needs %d more scrap." % (chip.price - Hangar.credits()))
		return
	store()
	menu.say("Bought a %s chip. Put it in a part's link socket." % chip.display_name.to_upper())


func _reroll() -> void:
	if not Hangar.reroll():
		menu.say("Needs %d more scrap." % (HangarStock.REROLL_COST - Hangar.credits()))
		return
	store((Hangar.state()["stock"] as Array).size())


func _best_mount(state: Dictionary, def: PartDef) -> StringName:
	var where := Loadout.mount_of(Loadout.preview(_catalog, state, def), def.id)
	if where != &"":
		return where
	for m in Hangar.ship().mounts:
		if Hangar.ship().accepts(m, def):
			return m
	return &"nose"


func _mount_row(mount: StringName) -> int:
	return maxi(Hangar.ship().mounts.find(mount), 0)
