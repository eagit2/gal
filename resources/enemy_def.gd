class_name EnemyDef
extends Resource

@export var id: StringName
@export var hp: int = 1
@export var score: int = 50
## Score when killed mid-dive.
@export var dive_score: int = 100
## Path speed in pixels per second (entries, dives, returning to formation).
@export var speed: float = 260.0
## StyledVisual scene (under assets/art/).
@export var visual_scene: PackedScene
## Dive shape modifiers, e.g. &"zigzag", &"wide".
@export var behaviors: Array[StringName] = []
## Aimed shots fired during each dive.
@export var dive_shots: int = 1
@export var bullet_speed: float = 300.0
