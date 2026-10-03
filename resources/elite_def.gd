class_name EliteDef
extends Resource
## A tough named enemy with one trait (EliteTrait) the player has to work around. Elites enter
## after the stage's waves start, patrol the upper screen, fire fans at the player, and stay
## until destroyed. The stage isn't cleared while one lives.

@export var id: StringName
@export var display_name: String
## One line shown when it arrives: what it does and how to beat it.
@export var hint: String
@export var hp: int = 40
@export var score: int = 2000
## Scrap it leaves, split into a few piles.
@export var scrap: int = 20
## Patrol speed, pixels per second.
@export var speed: float = 70.0
## Seconds between fans of aimed shots.
@export var fire_interval: float = 1.6
@export var fan_shots: int = 3
@export var bullet_speed: float = 260.0
@export var visual_scene: PackedScene
@export var visual_scale: float = 1.8
@export var tint: Color = Color.WHITE
@export var trait_logic: EliteTrait
