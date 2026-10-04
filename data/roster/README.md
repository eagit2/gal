# Roster sheet

Every enemy, elite and boss is a row in one of three tables. Edit a number, save, and the game uses it the next time it starts. You don't need to touch any code.

| File | What's in it |
|---|---|
| `enemies.csv` | Regular enemies (formation and divers) |
| `elites.csv` | Elites (tough named enemies with traits) |
| `bosses.csv` | Bosses: elites whose traits change in phases as they lose hp |
| `elite_levels.csv` | Elite difficulty levels 1 to 4: multipliers on hp, speed, damage and perk power, and the first stage each can roll on |
| `TRAITS.md` | Every trait you can use, what it does, and its settings with defaults |

You can open the files in Google Sheets or Excel, or edit them on GitHub (pencil icon). Keep the header row. Rows starting with `#` are ignored.

## Columns

**Shared columns:**
- `id`: the name used everywhere else (stages, test links). Lowercase with underscores.
- `visual`: sprite scene from `assets/art/dusk_armada/enemies/`, e.g. bee, moth, warden, lancer, spinner, fusewing, shieldbearer.
- `scale`: sprite size, e.g. 1.0.
- `tint`: color multiplier `r g b` (1 1 1 = unchanged; above 1 brightens).
- `hp`, `speed`, `score`, `bullet_speed`: numbers.

**Enemy columns:**
- `brain`: how it attacks once it dives: swarmer, strafer, hunter, puppet, escort.
- `dive_score`: score for a kill mid-dive.
- `scrap_chance` (0 to 1) and `scrap`: the scrap pile it leaves.
- `can_capture`: true or false, for tractor-beam capture runs.

**Elite and boss columns:**
- `name`: shown in the game.
- `hint`: one line of advice.
- `scrap`: scrap the elite leaves.
- `fire_interval`: seconds between fans.
- `fan_shots`: shots per fan.

**`traits`:** one or more traits separated by `;`. Settings go in brackets, separated by spaces:

```
blink
blink(interval=1.0 distance=90); plate(hp=6)
split(fragment=bee count=3)
```

**`phases`** (bosses only): `percent: traits` blocks separated by `|`. Each phase starts when the boss's hp drops to that percent of max and runs its traits on top of the boss's own `traits`:

```
100: shield_link; puppeteer | 65: hive_tow; mirror | 30: meteor_call; sweep(interval=4.5)
```

## Elite levels

`elite_levels.csv` has one row per level. Every elite and boss rolls a level when it spawns, from the levels whose `from_stage` has been reached. `hp`, `speed` (movement and bullets) and `damage` multiply the elite's numbers. `perk` makes its traits stronger: counts, radii and speeds grow, waits (intervals, telegraphs) shrink, and hit-point settings follow `hp`. Test one with `?elite=<id>&level=3`.

## Adding a new type

Add a row with a new `id`, then use it:
- Try it at once with `?spawn=<id>` (enemy: every wave flies it) or `?elite=<id>` (elite or boss: it joins at 4 s). For example, https://eagit2.github.io/gal/?spawn=blinker&god=1
- Put it in a stage:
  - An enemy goes in a wave's `enemy_id`.
  - An elite or boss goes in the stage's `elite_ids` (always appears) or `elite_pool_ids` (random each run).

A brand-new behavior (not a mix of existing traits) still needs a trait script. Add it to the list in `autoload/roster.gd`, then re-run `tools/roster_export.gd` to refresh TRAITS.md.

## Checking your edits

The game reports sheet mistakes (an unknown trait, a misspelled setting, a missing visual) as errors at startup. The test suite fails on any of them: `godot --headless -s res://tests/run_tests.gd`.

## How it works

At startup `autoload/roster.gd` reads the sheets. A row whose id has a `data/enemies/<id>.tres` or `data/elites/<id>.tres` file overrides that file's values in memory, so the stages that point at the file get the sheet's numbers. A row without a file becomes a new type. The sheet always wins.

`godot --headless -s res://tools/roster_export.gd` rebuilds enemies.csv, elites.csv and TRAITS.md from the .tres files. Use it only to regenerate TRAITS.md, or when starting over: delete the CSVs first, or the export reads the sheet's own values back.
