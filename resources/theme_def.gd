class_name ThemeDef
extends Resource
## Art-style hook: everything visual a sector needs, swappable between pixel and neon.

@export var id: StringName
@export var palette: Array[Color] = []
@export var background_scene: PackedScene
@export var music: AudioStream
