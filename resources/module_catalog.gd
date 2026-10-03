class_name ModuleCatalog
extends Resource
## Every frame and module. Registered here because web builds can't list folders (a test checks
## nothing in data/hangar is missing).

@export var frames: Array[FrameDef] = []
@export var modules: Array[ModuleDef] = []
## Modules owned by a new save.
@export var starter_modules: Array[StringName] = []


func module(id: StringName) -> ModuleDef:
	for m in modules:
		if m.id == id:
			return m
	return null


func frame(id: StringName) -> FrameDef:
	for f in frames:
		if f.id == id:
			return f
	return null
