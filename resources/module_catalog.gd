class_name ModuleCatalog
extends Resource
## Every frame, module and pilot. Registered here because web builds can't list folders (a test checks
## nothing in data/hangar is missing).

@export var frames: Array[FrameDef] = []
@export var modules: Array[ModuleDef] = []
## The first pilot is free and owned by a new save.
@export var pilots: Array[PilotDef] = []
## Modules owned by a new save.
@export var starter_modules: Array[StringName] = []


func module(id: StringName) -> ModuleDef:
	for m in modules:
		if m.id == id:
			return m
	return null


func pilot(id: StringName) -> PilotDef:
	for p in pilots:
		if p.id == id:
			return p
	return null


func frame(id: StringName) -> FrameDef:
	for f in frames:
		if f.id == id:
			return f
	return null
