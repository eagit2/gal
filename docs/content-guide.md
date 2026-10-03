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
Upgrades live in the hangar: add a `PartDef` under `data/hangar/parts/` and list it in `data/hangar/catalog.tres` (see docs/hangar.md). Effects use {"stat", "op", "value"} with a stat from `UpgradeSystem.BASE_STATS`.

### Add an enemy trait
Regular enemies can carry one `EnemyDef.trait_logic`: a sub-resource of an `EnemyTrait` script in `scenes/enemies/traits/` (Blink, Dash, Rock Drop). Override `begin` and `tick`; keep per-enemy state in `enemy.trait_state`. Anything falling that should crush enemies gets a `Crusher` Area2D (`scenes/components/crusher.gd`, mask 2).

### Add an elite
Create `data/elites/<id>.tres` (`EliteDef`): name, hint (shown on arrival: what it does and how to beat it), hp, score, scrap, patrol speed, fire pattern, visual (an enemy visual scene, scaled and tinted), and `trait_logic`, a sub-resource of an `EliteTrait` script in `scenes/enemies/elites/` (Frost Shell, Rock Tow, Shield Link). A new trait is a new script overriding `begin`, `tick`, `absorb` and `end`; keep per-elite state in `elite.state`. Put elites in a stage with `StageDef.elites`. Test one anywhere with the dev option `elite=<id>`.

Effects are `{"stat": &"...", "op": &"add"|"mul"|"max", "value": ...}`. Stats and their defaults are `UpgradeSystem.BASE_STATS` (`systems/upgrade_system.gd`); `lives` is applied once on pickup. A new stat needs a line in BASE_STATS and code that reads it.

## Synergy
`data/synergies/<id>.tres` (`SynergyDef`): required_tags and effects. It switches on when the player owns upgrades covering every tag. Register it in the pool.

## Drops
Scrap: `EnemyDef.scrap_chance` and `scrap`; `DifficultyDef.drop_mult`; pity step in `systems/drop_system.gd`. Capture: `EnemyDef.can_capture`, `data/brains/capture.tres`, timing in `systems/capture_system.gd`.

## Combo mode
`data/combos/<id>.tres` (`ComboDef`): style (theme id), threshold, decay_delay, decay_rate, duration, effects (same format as upgrades), HUD color. What fills each meter is in `systems/combo_tracker.gd`; thresholds scale with `DifficultyDef.combo_threshold`.

## Hangar part
`data/hangar/parts/<id>.tres` (`PartDef`): category (weapon, shield, power, engine, extra, chip), tier (sets the scrap price per rank), rank_text (3 lines for the store), effects (each with an optional "rank" it starts at), and part (sprite in `assets/art/dusk_armada/parts/`). Register it in `data/hangar/catalog.tres` (a test fails if you forget). Placement bonuses by category and mount are `placement` in the catalog.

## Hangar ship
`data/hangar/ships/<id>.tres` (`ShipDef`): slots per type (weapon, shield, power, bonus), mounts, sprite. Register it in the catalog. Hull palettes are `FRAME_PALS` in `tools/art/gen_dusk_armada.py`.

## Pilot
`data/hangar/pilots/<id>.tres` (`PilotDef`): bio, cost, color, power (Overclock, Bulwark, Phase Dash, Nova), power_name, power_text, cooldown, duration, effects (Overclock), distance (dash), damage (Nova). Register it in the catalog's `pilots`; the first one is free.

## Stage medal
`data/medals/<id>.tres` (`MedalDef`): goal (`NO_DAMAGE`, `PERFECT`, `ACCURACY`, `GRAZES`), target, currency. Point `StageDef.medal` at it. It pays once per run, scaled by `DifficultyDef.score_multiplier`.

## Sound and music
- New sound effect: add a function to `tools/audio/gen_sfx.py` and its entry in `SOUNDS`, run `python3 tools/audio/gen_sfx.py`, then add an `SfxDef` to `data/audio/sound_bank.tres` (id, stream, volume, cooldown, priority). Play it from `systems/audio_cues.gd` on an EventBus signal, or with `AudioManager.play(&"id")` from UI.
- New music: add a track function to `tools/audio/tracks.py`, run `python3 tools/audio/gen_music.py <name>`, set `loop=true` in its `.ogg.import`, then point a `ThemeDef.music`, `SoundBank.boss_music` or a `SoundBank.scene_music` entry at it.
- Enemy death sound: `EnemyDef.death_sound` (a SoundBank id).
