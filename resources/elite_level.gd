class_name EliteLevel
extends Resource
## One elite difficulty level (data/roster/elite_levels.csv): multipliers on an elite's or boss's
## hp, speed (movement and bullets), shot damage and perk power, and the first stage it can roll.

@export var level: int = 1
@export var hp: float = 1.0
@export var speed: float = 1.0
@export var damage: float = 1.0
## Perk power: counts, radii and speeds grow, waits (intervals, telegraphs) shrink.
@export var perk: float = 1.0
## First stage number (1-based) this level can appear on.
@export var from_stage: int = 1
