class_name StageDef
extends Resource

@export var id: StringName
@export var waves: Array[WaveDef] = []
@export var is_challenge: bool = false
@export var modifiers: Array[StringName] = []
@export_range(0, 3) var music_intensity: int = 1
