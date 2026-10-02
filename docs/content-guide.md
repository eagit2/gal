# Content guide

How to add content without touching code. Filled in as each system lands.

## Difficulty (M4)
Create `data/difficulty/<id>.tres` of type `DifficultyDef`.

## Enemy (M1/M2)
Create `data/enemies/<id>.tres` of type `EnemyDef`; set `visual_scene` to a scene under `assets/art/<style>/enemies/`.

## Upgrade (M3)
Create `data/upgrades/<id>.tres` of type `UpgradeDef`. Effects are `{"stat", "op", "value"}` dictionaries.
