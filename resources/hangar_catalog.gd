class_name HangarCatalog
extends Resource
## Every ship, part and pilot. Registered here because web builds can't list folders (a test checks
## nothing in data/hangar is missing).

@export var ships: Array[ShipDef] = []
@export var parts: Array[PartDef] = []
@export var chips: Array[ChipDef] = []
@export var combos: Array[LinkComboDef] = []
## The first pilot is free and owned by a new save.
@export var pilots: Array[PilotDef] = []
## Parts a new save owns at rank 1, and where they start: {mount: part id}.
@export var starter_mounts := {}
## Extra effects by where a part sits: {category name (lowercase): {mount: [effects]}}.
@export var placement := {}


func part(id: StringName) -> PartDef:
	for p in parts:
		if p.id == id:
			return p
	return null


func chip(id: StringName) -> ChipDef:
	for c in chips:
		if c.id == id:
			return c
	return null


## The combo two chips make in a linked pair, or null.
func combo_for(a: StringName, b: StringName) -> LinkComboDef:
	for c in combos:
		if c.matches(a, b):
			return c
	return null


func pilot(id: StringName) -> PilotDef:
	for p in pilots:
		if p.id == id:
			return p
	return null


func ship(id: StringName) -> ShipDef:
	for s in ships:
		if s.id == id:
			return s
	return null


func placement_effects(def: PartDef, mount: StringName) -> Array[Dictionary]:
	var by_mount: Dictionary = placement.get(String(PartDef.Category.keys()[def.category]).to_lower(), {})
	var result: Array[Dictionary] = []
	result.assign(by_mount.get(String(mount), []))
	return result
