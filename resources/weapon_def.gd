class_name WeaponDef
extends Resource

@export var id: StringName
@export var fire_rate: float = 6.0  # shots per second
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 900.0
@export var spread_count: int = 1
@export var spread_angle: float = 0.0
@export var damage: int = 1
