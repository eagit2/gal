class_name SoundBank
extends Resource
## Every sound effect plus music that doesn't come from an art style (ThemeDef.music covers those).

@export var sfx: Array[SfxDef] = []
## Played instead of the style's music on stages marked as boss stages (StageDef.boss).
@export var boss_music: AudioStream
## Scene file path -> music for menus that aren't the game scene (title, hangar, ...).
@export var scene_music: Dictionary = {}
