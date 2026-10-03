# Hangar: permanent ship upgrades

Status: v1 built 2026-10-03 (Ship upgrade hangar thread). Numbers are data in `data/hangar/` and `data/medals/`; tune freely.

## Economy
- **Credits** are the meta currency. They come only from **stage medals**: one optional goal per stage (`StageDef.medal`), paid the first time it's earned each run.
- Payout = `MedalDef.currency` x `DifficultyDef.score_multiplier` (Cadet 0.75, Pilot 1, Ace 1.5, Nightmare 2.5).
- Credits are saved the moment a medal is earned, so dying never loses them. They live in the meta save (`currency`, `hangar` keys of `user://save.json`), beside the run checkpoint, which a game over clears.
- A full Sector 1 run on Pilot pays roughly 250 to 300 credits once all 10 stages have medals. Buying every v1 node costs 1,725, about 6 good runs.

## Medals (v1)
Placeholders until M5 builds the design goals in `design/intro-levels.md`.

| Stage | Medal | Goal | Credits |
|---|---|---|---|
| Stage 1 | Untouched | lose no ship | 20 |
| Stage 2 | Sharpshooter | 60% of shots hit | 25 |
| Challenge 1 | Perfect | no enemy escapes | 40 |

Goal types: `NO_DAMAGE`, `PERFECT`, `ACCURACY`, `GRAZES`. A new goal type is one enum value and one `match` line in `MedalTracker`.

## Upgrade tree (v1)
Each rank applies its effect once more, under every run's card upgrades (`GameState.set_meta_effects`). A node with a requirement unlocks when the required node has one rank.

| Branch | Node | Per rank | Ranks | Costs | Needs |
|---|---|---|---|---|---|
| Hull | Thruster Tuning | +5% move speed | 3 | 30 / 60 / 100 | |
| Hull | Shield Capacitor | shield recharges 10% faster | 3 | 40 / 80 / 120 | |
| Hull | Reinforced Bubble | shield absorbs +1 hit | 1 | 250 | Shield Capacitor |
| Weapons | Trigger Tuning | +5% fire rate | 3 | 40 / 80 / 120 | |
| Weapons | Velocity Rails | shots 10% faster | 2 | 30 / 60 | |
| Weapons | Wing Drone | start with a drone | 1 | 300 | Trigger Tuning |
| Systems | Salvage Scanner | drops 10% more likely | 3 | 30 / 60 / 100 | |
| Systems | Tractor Field | pickup pull +60 px | 2 | 25 / 50 | |
| Systems | Combo Primer | combo meters 10% faster | 2 | 50 / 100 | Salvage Scanner |

## Planned next (architecture: "unlocks widen options more than they add raw power")
- **Armory:** unlock new upgrade cards into the run pool (filter `UpgradeSystem.available()` by owned unlock ids). Needs game code after PR #6 merges.
- **Spare Hull** (+1 starting life) and **Extra Card** (+1 card choice): need `game.gd` to read them at run start.
- **Ships:** alternate hulls with their own weapon and stats (M7).
- Stage 4 to 10 medals and the real Sector 1 goals (M5).
