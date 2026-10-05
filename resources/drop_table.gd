class_name DropTable
extends Resource
## What a kill can drop besides scrap: items (hangar parts and chips, banked to the save when caught)
## and per-life power-ups. One drop per kill, by priority: item > power-up > scrap.

@export_group("Items")
## Chance a regular enemy drops a part from `enemy_tiers` (never chips).
@export var enemy_item := 0.005
## Chance an elite drops a part from `elite_tiers` or a chip from `elite_chips`.
@export var elite_item := 0.05
## Share of elite item drops that are chips instead of parts.
@export var elite_chip_share := 0.5
## Chance a boss drops a part from `boss_tiers`.
@export var boss_item := 0.15
## PartDef.Tier values each source draws parts from.
@export var enemy_tiers: Array[int] = [1, 2]
@export var elite_tiers: Array[int] = [3]
@export var boss_tiers: Array[int] = [4]
## Chips an elite can drop (common and rare).
@export var elite_chips: Array[StringName] = []
## Scrap paid instead when a caught part is already owned.
@export var owned_part_scrap := 100

@export_group("Power-ups")
@export var enemy_powerup := 0.015
@export var elite_powerup := 0.25
@export var boss_powerup := 1.0
## Each POWER or FIRE RATE pickup multiplies by this; capped at the max.
@export var powerup_step := 1.1
@export var max_power := 2.0
@export var max_fire_rate := 2.0
## Extra copies of every gun's volley (+1 shot each pickup).
@export var max_extra_volleys := 3
## Scrap paid for a power-up caught past its cap.
@export var capped_scrap := 25
