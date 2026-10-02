class_name StageDef
extends Resource

@export var id: StringName
@export var waves: Array[WaveDef] = []
## Challenging stage: enemies fly through without settling or shooting; hits earn a bonus.
@export var is_challenge: bool = false
## ThemeDef id forced for the whole stage; empty keeps the base style.
@export var style: StringName = &""
@export var modifiers: Array[StringName] = []
@export_range(0, 3) var music_intensity: int = 1
