class_name EnemyDef
extends Resource

@export var id: StringName
@export var hp: int = 1
@export var score: int = 100
@export var speed: float = 200.0
@export var visual_scene: PackedScene
@export var behaviors: Array[StringName] = []
