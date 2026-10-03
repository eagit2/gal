class_name HangarParts
extends RefCounted
## Hangar part menus, drawn into the hangar's list: a slot's categories, a category's parts (the
## highlighted one opens in place with its attributes and sockets; selecting it again opens it), a
## part's attributes (upgrade each level with scrap, then fit it), and the rotating store.

## Milliseconds a card must have been open before a press opens the part (a tap opens it first).
const OPEN_DELAY := 200

var menu: Control  # scenes/main/hangar.gd
var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")
var _open_card: Button
var _opened_at := 0


func _init(owner: Control) -> void:
	menu = owner


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
		menu.add(HangarUI.row(HangarUI.CATEGORY_NAMES[cat], "", "%d / %d >" % [owned.size(), all.size()], HangarUI.CATEGORY_COLORS[cat]), describe(current, mount), category.bind(mount, cat))
	menu.add(HangarUI.row("< BACK"), describe(current, mount), menu.home.bind(_mount_row(mount)))
	menu.say(describe(current, mount) if current else "Empty slot.")
	if focus_row < 0:
		focus_row = PartDef.MENU_CATEGORIES.find(current.category) if current else 0
	menu.focus(maxi(focus_row, 0))


## A category's parts for `mount`: owned ones first, then the rest with their store state.
func category(mount: StringName, cat: int, focus_part: PartDef = null) -> void:
	var state := Hangar.state()
	var back: Callable = menu.home.bind(_mount_row(mount)) if mount == &"nose" else slot.bind(mount, PartDef.MENU_CATEGORIES.find(cat))
	menu.page("%s  %s" % [menu.MOUNT_NAMES[mount], HangarUI.CATEGORY_NAMES[cat]], back)
	_open_card = null
	var list := _catalog.parts.filter(func(p: PartDef) -> bool: return p.category == cat)
	list.sort_custom(func(a: PartDef, b: PartDef) -> bool: return Loadout.owns(state, a.id) and not Loadout.owns(state, b.id))
	var focus_row := 0
	for def: PartDef in list:
		if def == focus_part or (focus_part == null and Loadout.part_at(_catalog, state, mount) == def):
			focus_row = menu.row_count()
		var color := HangarUI.GOOD if Loadout.owns(state, def.id) else (HangarUI.GOLD if HangarStock.in_stock(state, def.id) else HangarUI.DIM)
		var row := HangarUI.row(def.display_name.to_upper(), "", _status(state, def, mount), HangarUI.TIER_COLORS[def.tier], color)
		var card := HangarCards.drop_card(row, _final_stats(state, mount, def), Loadout.sockets(_catalog, state, def), HangarUI.CATEGORY_COLORS[def.category])
		menu.add(card, describe(def, mount), _press.bind(card, part.bind(mount, def, back)), _fitted(state, mount, def))
		card.focus_entered.connect(_open.bind(card))
	if list.is_empty():
		menu.add(HangarUI.row("NONE YET"), "More parts arrive with combos.", back)
	menu.add(HangarUI.row("< BACK"), "", back)
	menu.focus(focus_row)


## Attribute rows for a drop card: name, level, max and the stat it reaches with the part fitted.
func _final_stats(state: Dictionary, mount: StringName, def: PartDef) -> Array:
	var stats := _stats(_fitted(state, mount, def))
	var rows := []
	for a in def.attributes:
		var stat: StringName = a["effects"][0]["stat"]
		rows.append([a["name"], Loadout.level(state, def.id, a["id"]), int(a["max"]), StatWords.value(stat, stats[stat])])
	return rows


func _open(card: Button) -> void:
	if _open_card == card:
		return
	if is_instance_valid(_open_card):
		HangarCards.set_open(_open_card, false)
	_open_card = card
	_opened_at = Time.get_ticks_msec()
	HangarCards.set_open(card, true)


## First press opens the card; a press on an open card runs `action`.
func _press(card: Button, action: Callable) -> void:
	if _open_card != card:
		_open(card)
	elif Time.get_ticks_msec() - _opened_at >= OPEN_DELAY:
		action.call()


## A part: its attributes with an upgrade per level, its link sockets, then fit, buy or back.
func part(mount: StringName, def: PartDef, back: Callable, focus_row := 0) -> void:
	var state := Hangar.state()
	menu.page(def.display_name.to_upper(), back)
	var owned := Loadout.owns(state, def.id)
	var summary := describe(def, mount)
	var now := _stats(_fitted(state, mount, def))
	for a in def.attributes:
		var lv := Loadout.level(state, def.id, a["id"])
		var price := Loadout.upgrade_price(state, def, a["id"])
		var maxed := lv >= int(a["max"])
		var after := _fitted(state, mount, def)
		if not maxed:
			after["parts"][String(def.id)][String(a["id"])] = lv + 1
		var change := StatWords.change(a["effects"], now, _stats(after))
		var right := "MAX" if maxed else ("%d" % price if owned else "")
		var color := HangarUI.GOOD if maxed else (HangarUI.GOLD if price <= Hangar.credits() else HangarUI.ROSE)
		var text := "%s  level %d / %d\n%s.\n%s" % [a["name"], lv, int(a["max"]), a["text"], "Buy the part first." if not owned else ("Maxed." if maxed else "Next level: " + change)]
		menu.add(HangarUI.upgrade_card(a["name"], lv, int(a["max"]), HangarUI.CATEGORY_COLORS[def.category], change, right, color), text, _upgrade.bind(mount, def, a["id"], back))
	var links := HangarUI.row("LINKS")
	var sockets := HangarCards.sockets(Loadout.sockets(_catalog, state, def), 22)
	sockets.position = Vector2(140, 11)
	links.add_child(sockets)
	menu.add(links, "Link sockets: chips go here, and linked chips combo. Chips arrive with combos.", func() -> void: pass)
	var where := Loadout.mount_of(state, def.id)
	if owned and where == mount:
		menu.add(HangarUI.row("FITTED ON %s" % menu.MOUNT_NAMES[mount], "", "", Color.TRANSPARENT, HangarUI.GOOD), summary, back)
	elif owned and Hangar.ship().accepts(mount, def):
		menu.add(HangarUI.row("FIT TO %s" % menu.MOUNT_NAMES[mount]), summary, _fit.bind(mount, def.id), _fitted(state, mount, def))
	elif HangarStock.in_stock(state, def.id):
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


func _status(state: Dictionary, def: PartDef, mount: StringName) -> String:
	var where := Loadout.mount_of(state, def.id)
	if where == mount:
		return "FITTED"
	if where != &"":
		return "ON %s" % menu.MOUNT_NAMES[where]
	if Loadout.owns(state, def.id):
		return "OWNED"
	return str(def.price()) if HangarStock.in_stock(state, def.id) else "-"


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


func _fit(mount: StringName, id: StringName) -> void:
	var state := Hangar.state().duplicate(true)
	if not _force_place(state, mount, id):
		menu.say("That part can't go on the %s." % menu.MOUNT_NAMES[mount])
		return
	Hangar.set_mounts(state["mounts"])
	menu.home(_mount_row(mount))


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
	menu.say("Bought. Upgrade its attributes above, or fit it to the %s." % menu.MOUNT_NAMES[mount])


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
