# Content guide

How to add content without touching code. Filled in as each system lands.

## Difficulty
`data/difficulty/{cadet,pilot,ace,nightmare}.tres` (`DifficultyDef`). The game scene currently uses `pilot`; difficulty select arrives in M4.

## Enemy
Create `data/enemies/<id>.tres` of type `EnemyDef` (hp, score, fire_interval, bullet_speed, placeholder color). Until art lands, enemies use the placeholder polygons in `scenes/enemies/enemy.tscn` tinted by `color`; later set `visual_scene` to a scene under `assets/art/<style>/enemies/`.

## Weapon
Create `data/weapons/<id>.tres` of type `WeaponDef` (fire_rate, projectile_scene, projectile_speed, spread_count, spread_angle, damage).

## Upgrade (M3)
Create `data/upgrades/<id>.tres` of type `UpgradeDef`. Effects are `{"stat", "op", "value"}` dictionaries.
