class_name EnemyDef
extends Resource

@export var id: StringName
@export var hp: int = 1
@export var score: int = 100
@export var speed: float = 200.0
@export var visual_scene: PackedScene
@export var behaviors: Array[StringName] = []
## Average seconds between shots (randomized per enemy). 0 means never fires.
@export var fire_interval: float = 6.0
@export var bullet_speed: float = 280.0
@export var color: Color = Color(1, 0.8, 0.2)  # placeholder visual until art lands
