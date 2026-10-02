class_name ThemeDef
extends Resource
## One art style (see docs/combo-styles.md). StyledVisual nodes show the child named after `id`.

@export var id: StringName
@export var display_name: String
## &"pixel" or &"vector". Vector themes without a dedicated visual get a generated wireframe.
@export var family: StringName = &"pixel"
@export var palette: Array[Color] = []
@export var music: AudioStream
