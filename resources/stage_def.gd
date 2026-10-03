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
## Elites that join this stage, `elite_delay` seconds in and `elite_gap` apart. The stage isn't
## cleared while one lives.
@export var elites: Array[EliteDef] = []
@export var elite_delay: float = 9.0
@export var elite_gap: float = 12.0
## Boss stage: plays SoundBank.boss_music instead of the style's music.
@export var boss: bool = false
