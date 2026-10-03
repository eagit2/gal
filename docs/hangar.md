# Hangar: frames, modules and upgrade chains

Status: v2 built 2026-10-03 (Ship upgrade hangar thread). Eric asked for a deeper, materia-style menu with upgrade chains, and a visible change on the ship for every upgrade. All numbers are data in `data/hangar/` and `data/medals/`.

## Economy
- **Credits** come from **stage medals** (one optional goal per stage, `StageDef.medal`), paid once per run and scaled by `DifficultyDef.score_multiplier`. They're saved right away, so dying never loses them.
- Credits buy **modules** and **frames** in the shop.
- **AP:** every equipped module earns 1 AP per kill (granted at stage clear and run end). AP raises its level.

## Frames (the ship)
| Frame | Slots | Linked pairs | Perk | Cost |
|---|---|---|---|---|
| Kestrel | 3 | 1 | starter | 0 |
| Talon | 4 | 2 | +5% speed | 200 |
| Bastion | 5 | 2 | +1 shield layer, -5% speed | 450 |
| Seraph | 6 | 3 | +5% fire rate | 900 |

Each frame has its own hull colors. Slots 1-2, 3-4 and 5-6 are linked when the frame has that many pairs.

## Modules (materia)
Colors: green weapon, blue support, yellow system, purple hull. Each module levels 1 to 3 from AP. Each level adds its `per_level` effect. **Mastery** (max level) spawns a free level-1 copy once and unlocks its chain module in the shop.

- **Weapon:** Twin Cannon, Heavy Rounds, Pierce Lens, Missile Pod, Drone Bay. Chains: Twin Cannon to Spread Cannon, Missile Pod to Swarm Rack.
- **Support** (works only in a linked slot): Amplifier (partner +1 level; chain to Overlink, +2), Seeker (homing), Volatile (kill blasts), Rapid Link (fire rate). The last three need a weapon partner.
- **System:** Magnet Coil, Salvage Scanner, Score Uplink (chain to Jackpot Uplink), Graze Coil, Combo Primer.
- **Hull:** Thrusters, Capacitor (chain to Bubble Layer).
- New saves start with Thrusters and Magnet Coil.

## Ship visuals
Every equipped module adds a pixel part at its slot (wingtips, nose, tail, shoulders), with an orb in its color. It glows brighter as it levels. Parts are drawn by `assets/art/dusk_armada/ship_parts.gd` inside the player's Dusk Armada visual only (drones and other styles don't show them). Art: `PARTS` and `FRAME_PALS` in `tools/art/gen_dusk_armada.py`.

## Menu
Title > HANGAR: a ship preview, then LOADOUT (choose a slot, then a module), MODULES (levels and AP), SHOP (modules, locked chains show what unlocks them), and FRAMES (buy or switch). Cancel goes back one level.

## Next
- Pilots with unique powers (waiting on Eric's pick: active, passive, or both).
- Medals for stages 4 to 10 and the real Sector 1 goals (M5).
