# Content guide

How to add content without touching code. Filled in as each system lands.

## Difficulty
`data/difficulty/{cadet,pilot,ace,nightmare}.tres` (`DifficultyDef`). The game scene currently uses `pilot`; difficulty select arrives in M4.

## Enemy
`data/enemies/<id>.tres` (`EnemyDef`): hp, score, dive_score, speed (entry and return), bullet_speed, `brain` (a `data/brains/*.tres`: swarmer, strafer, hunter; tune speeds, turn rates and fire rates there), and `visual_scene`. The visual is a StyledVisual scene (see `assets/art/dusk_armada/enemies/`): a child named `dusk_armada` holding the base sprite and a hidden `Silhouette` of polygons, plus optional children named after other theme ids. Vector themes generate a wireframe from the base polygons using `neon_color`.

## Paths
`data/paths/<id>.tres` are Curve2D resources in screen coordinates (540x960). Entry paths end near the formation; challenge paths should exit the screen.

## Stages and sectors
`data/stages/<id>.tres` (`StageDef`) holds WaveDefs as sub-resources: enemy, count, entry_path, formation_slots (one Vector2i(column, row) per enemy, grid 10x5), delay. `is_challenge` makes enemies fly through; `style` forces a theme for the stage. `data/sectors/<id>.tres` lists stages in play order; the game loops them with rising aggression. `tests/unit/test_stage_data.gd` checks slots are unique and on the grid.

To test a stage without playing up to it, add URL options to the build: `?stage=3` (number or id like `challenge_1`), `god=1` (hits cost no lives), `repeat=1` (replay the stage), `difficulty=ace`. Example: https://eagit2.github.io/gal/?stage=challenge_1&god=1&repeat=1. Locally: `godot -- stage=3 god=1`. See `systems/dev_options.gd`.

## Art styles
`data/themes/<id>.tres` (`ThemeDef`): id, family (`pixel` or `vector`), palette, optional `post_shader` (full-screen, for pixel styles like Pocket Four) and `wire_tint` (vector wireframes). Register new themes in `autoload/style_director.gd` (THEMES). Backgrounds are children of `scenes/game/background.tscn` named after the theme id.

## Weapon
Create `data/weapons/<id>.tres` of type `WeaponDef` (fire_rate, projectile_scene, projectile_speed, spread_count, spread_angle, damage).

## Upgrade
Create `data/upgrades/<id>.tres` of type `UpgradeDef` and add it to `data/upgrades/upgrade_pool.tres` (a test fails if you forget). Fields: source (UTILITY for gold capsules, BULLET for regular capsules; bullet upgrades may only change bullet stats, a test checks), display_name, description (toast text), category, rarity (drop weights 70/25/5 in the pool), tags (for synergies), max_stacks, requires (upgrade ids), effects.

Effects are `{"stat": &"...", "op": &"add"|"mul"|"max", "value": ...}`. Stats and their defaults are `UpgradeSystem.BASE_STATS` (`systems/upgrade_system.gd`); `lives` is applied once on pickup. A new stat needs a line in BASE_STATS and code that reads it.

## Synergy
`data/synergies/<id>.tres` (`SynergyDef`): required_tags and effects. It switches on when the player owns upgrades covering every tag. Register it in the pool.

## Drops
`EnemyDef.drop_chance` and `drop_rarity_bonus`; `DifficultyDef.drop_mult`; pity step in `systems/drop_system.gd`.

## Combo mode
`data/combos/<id>.tres` (`ComboDef`): style (theme id), threshold, decay_delay, decay_rate, duration, effects (same format as upgrades), HUD color. What fills each meter is in `systems/combo_tracker.gd`; thresholds scale with `DifficultyDef.combo_threshold`.

## Hangar module
`data/hangar/modules/<id>.tres` (`ModuleDef`): kind (weapon, support, system, hull), cost, effects (level 1), per_level (added per level above 1), ap_levels, part (sprite in `assets/art/dusk_armada/parts/`), and for support modules amplify and link_kind. Set `requires_mastered` to make it a chain unlock. Register it in `data/hangar/catalog.tres` (a test fails if you forget).

## Hangar frame
`data/hangar/frames/<id>.tres` (`FrameDef`): slots, pairs, effects, cost, sprite. Register it in the catalog. Hull palettes are `FRAME_PALS` in `tools/art/gen_dusk_armada.py`.

## Pilot
`data/hangar/pilots/<id>.tres` (`PilotDef`): bio, cost, color, power (Overclock, Bulwark, Phase Dash, Nova), power_name, power_text, cooldown, duration, effects (Overclock), distance (dash), damage (Nova). Register it in the catalog's `pilots`; the first one is free.

## Stage medal
`data/medals/<id>.tres` (`MedalDef`): goal (`NO_DAMAGE`, `PERFECT`, `ACCURACY`, `GRAZES`), target, currency. Point `StageDef.medal` at it. It pays once per run, scaled by `DifficultyDef.score_multiplier`.

## Sound and music
- New sound effect: add a function to `tools/audio/gen_sfx.py` and its entry in `SOUNDS`, run `python3 tools/audio/gen_sfx.py`, then add an `SfxDef` to `data/audio/sound_bank.tres` (id, stream, volume, cooldown, priority). Play it from `systems/audio_cues.gd` on an EventBus signal, or with `AudioManager.play(&"id")` from UI.
- New music: add a track function to `tools/audio/tracks.py`, run `python3 tools/audio/gen_music.py <name>`, set `loop=true` in its `.ogg.import`, then point a `ThemeDef.music`, `SoundBank.boss_music` or a `SoundBank.scene_music` entry at it.
- Enemy death sound: `EnemyDef.death_sound` (a SoundBank id).
