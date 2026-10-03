class_name StageDef
extends Resource

@export var id: StringName
@export var waves: Array[WaveDef] = []
## Challenging stage: enemies fly through without settling or shooting; hits earn a bonus.
@export var is_challenge: bool = false
## ThemeDef id forced for the whole stage; empty keeps the base style.
@export var style: StringName = &""
## Extra squads that fly into empty formation slots once the main waves are in and the
## formation thins out below `reinforce_below` enemies.
@export var reinforcements: int = 0
@export var reinforcement_size: int = 8
@export var reinforce_below: int = 18
@export var modifiers: Array[StringName] = []
@export_range(0, 3) var music_intensity: int = 1
## Optional goal that pays hangar credits once per run (see MedalTracker).
@export var medal: MedalDef
