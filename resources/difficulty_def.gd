class_name DifficultyDef
extends Resource

@export var id: StringName
@export var display_name: String
## Ships per run; the Spare Hull hangar part adds more.
@export var lives: int = 1
@export var enemy_bullet_speed: float = 1.0
@export var dive_frequency: float = 1.0
## Rate of shots from enemies sitting in formation.
@export var formation_fire: float = 1.0
## Seconds for the shield bubble to come back after it pops.
@export var shield_recharge: float = 12.0
## Scales upgrade drop chance.
@export var drop_mult: float = 1.0
## Scales combo meter thresholds.
@export var combo_threshold: float = 1.0
@export var enemy_hp: float = 1.0
@export var score_multiplier: float = 1.0
## First sector (0-based) where stage modifiers apply. -1 means never.
@export var modifiers_from_sector: int = -1
