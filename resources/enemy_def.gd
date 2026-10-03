class_name EnemyDef
extends Resource

@export var id: StringName
@export var hp: int = 1
@export var score: int = 50
## Score when killed mid-dive.
@export var dive_score: int = 100
## Speed in pixels per second when entering and flying back to formation.
@export var speed: float = 260.0
## StyledVisual scene (under assets/art/).
@export var visual_scene: PackedScene
## How it attacks once it leaves formation (scenes/enemies/behaviors/, data in data/brains/).
@export var brain: EnemyBrain
@export var bullet_speed: float = 300.0
## Chance per kill to drop an upgrade pickup (design/intro-levels.md 2.1).
@export var drop_chance: float = 0.02
## Rarity tiers added to this enemy's drops (wardens: +1).
@export var drop_rarity_bonus: int = 0
