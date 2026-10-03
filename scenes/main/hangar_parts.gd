class_name HangarParts
extends RefCounted
## Hangar part menus, drawn into the hangar's list: a slot's categories, a category's parts, a
## part's attributes (upgrade each level with scrap, then fit it), and the rotating store.

const PIPS := 5

var menu: Control  # scenes/main/hangar.gd
var _catalog: HangarCatalog = preload("res://data/hangar/catalog.tres")


func _init(owner: Control) -> void:
	menu = owner


## A slot: the categories it takes. The nose takes weapons only, so it goes straight to them.
func slot(mount: StringName) -> void:
	if mount == &"nose":
		category(mount, PartDef.Category.WEAPON)
		return
	var state := Hangar.state()
	var current := Loadout.part_at(_catalog, state, mount)
	menu.page("%s SLOT" % menu.MOUNT_NAMES[mount], menu.home.bind(_mount_row(mount)))
	var empty := state.duplicate(true)
	empty["mounts"][String(mount)] = ""
	for cat in range(PartDef.Category.SHIELD, PartDef.Category.size()):
		var all := _catalog.parts.filter(func(p: PartDef) -> bool: return p.category == cat)
		var owned := all.filter(func(p: PartDef) -> bool: return Loadout.owns(state, p.id))
		var right := "%d / %d" % [owned.size(), all.size()] if not all.is_empty() else "SOON"
		var text: String = HangarUI.CATEGORY_HINTS[cat] % menu.MOUNT_NAMES[mount].to_lower()
		menu.add(HangarUI.row(HangarUI.CATEGORY_NAMES[cat], "", right, HangarUI.CATEGORY_COLORS[cat]), text, category.bind(mount, cat))
	menu.add(HangarUI.row("- EMPTY -"), "Take the part off this slot.", _fit.bind(mount, &""), empty)
	menu.say(describe(current, mount) if current else "Empty slot. Pick what kind of part goes here.")
	menu.focus(current.category - PartDef.Category.SHIELD if current else 0)


## A category's parts for `mount`: owned ones first, then the rest with their store state.
func category(mount: StringName, cat: int, focus_part: PartDef = null) -> void:
	var state := Hangar.state()
	var back: Callable = menu.home.bind(_mount_row(mount)) if mount == &"nose" else slot.bind(mount)
	menu.page("%s  %s" % [menu.MOUNT_NAMES[mount], HangarUI.CATEGORY_NAMES[cat]], back)
	var list := _catalog.parts.filter(func(p: PartDef) -> bool: return p.category == cat)
	list.sort_custom(func(a: PartDef, b: PartDef) -> bool: return Loadout.owns(state, a.id) and not Loadout.owns(state, b.id))
	var focus_row := 0
	for def: PartDef in list:
		if def == focus_part or (focus_part == null and Loadout.part_at(_catalog, state, mount) == def):
			focus_row = menu.row_count()
		var right := _status(state, def, mount)
		var color := HangarUI.GOOD if Loadout.owns(state, def.id) else (HangarUI.GOLD if HangarStock.in_stock(state, def.id) else HangarUI.DIM)
		menu.add(HangarUI.row(def.display_name.to_upper(), HangarUI.levels_short(state, def), right, HangarUI.TIER_COLORS[def.tier], color), describe(def, mount), part.bind(mount, def, back), _fitted(state, mount, def))
	if list.is_empty():
		menu.add(HangarUI.row("NONE YET"), "Chips arrive with combos.", back)
	menu.focus(focus_row)


## A part: its attributes with an upgrade per level, then fit, buy or back.
func part(mount: StringName, def: PartDef, back: Callable, focus_row := 0) -> void:
	var state := Hangar.state()
	menu.page(def.display_name.to_upper(), back)
	var owned := Loadout.owns(state, def.id)
	var summary := describe(def, mount)
	for a in def.attributes:
		var lv := Loadout.level(state, def.id, a["id"])
		var price := Loadout.upgrade_price(state, def, a["id"])
		var right := "MAX" if lv >= int(a["max"]) else ("+ %d" % price if owned else "")
		var color := HangarUI.GOOD if price < 0 else (HangarUI.GOLD if price <= Hangar.credits() else HangarUI.ROSE)
		var text := "%s  level %d / %d\n%s.\n%s" % [a["name"], lv, int(a["max"]), a["text"], "Buy the part first." if not owned else ""]
		menu.add(HangarUI.row(a["name"], HangarUI.pips(lv, int(a["max"]), PIPS), right, HangarUI.CATEGORY_COLORS[def.category], color), text, _upgrade.bind(mount, def, a["id"], back))
	var where := Loadout.mount_of(state, def.id)
	if owned and where == mount:
		menu.add(HangarUI.row("FITTED ON %s" % menu.MOUNT_NAMES[mount], "", "", Color.TRANSPARENT, HangarUI.GOOD), summary, back)
	elif owned and Hangar.ship().accepts(mount, def):
		menu.add(HangarUI.row("FIT TO %s" % menu.MOUNT_NAMES[mount]), summary, _fit.bind(mount, def.id), _fitted(state, mount, def))
	elif HangarStock.in_stock(state, def.id):
		menu.add(HangarUI.row("BUY", "", str(def.price()), Color.TRANSPARENT, HangarUI.GOLD if def.price() <= Hangar.credits() else HangarUI.ROSE), summary, _buy.bind(mount, def, back), _fitted(state, mount, def))
	elif not owned:
		menu.add(HangarUI.row("NOT IN STOCK", "", "", Color.TRANSPARENT, HangarUI.DIM), "Not in the store right now. The stock changes after every run.", back)
	menu.add(HangarUI.row("BACK"), summary, back)
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
		menu.add(HangarUI.part_card(def, Loadout.preview(_catalog, state, def), Hangar.credits()), describe(def, mount), part.bind(mount, def, store.bind(menu.row_count())))
	if (state["stock"] as Array).is_empty():
		menu.add(HangarUI.row("SOLD OUT"), "You own every part. New ones come with combos.", menu.home)
	menu.add(HangarUI.row("REROLL", "", str(HangarStock.REROLL_COST)), "Swap the stock for new parts now instead of after the next run.", _reroll)
	menu.add(HangarUI.row("BACK"), "Back to the hangar.", menu.home.bind(Hangar.ship().mounts.size()))
	menu.focus(focus_row)


## Rarity, category, what it does, what `mount` adds, and which tree nodes it powers there.
func describe(def: PartDef, mount: StringName) -> String:
	if def == null:
		return ""
	var text := "%s %s. %s" % [HangarUI.TIER_NAMES[def.tier], HangarUI.CATEGORY_NAMES[def.category].to_lower().trim_suffix("s"), def.text]
	var placed := _catalog.placement_effects(def, mount)
	if not placed.is_empty():
		text += "\nOn %s: %s." % [menu.MOUNT_NAMES[mount], HangarUI.effect_words(placed)]
	var nodes := Hangar.ship().tree.filter(func(n: TreeNodeDef) -> bool: return n.mount == mount and def.tier >= n.min_tier)
	if not nodes.is_empty():
		text += "\nPowers %d blueprint node%s on %s." % [nodes.size(), "" if nodes.size() == 1 else "s", menu.MOUNT_NAMES[mount]]
	return text


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


## Places the part, first emptying any mount whose part fills the same slot type.
func _force_place(state: Dictionary, mount: StringName, id: StringName) -> bool:
	if id != &"" and not Loadout.can_place(_catalog, state, mount, _catalog.part(id)):
		for other in Loadout.ship_of(_catalog, state).mounts:
			var p := Loadout.part_at(_catalog, state, other)
			if other != mount and p and p.slot() == _catalog.part(id).slot():
				state["mounts"][String(other)] = ""
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
