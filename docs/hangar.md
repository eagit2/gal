# Hangar: ship slots, parts, placement and the store

Status: v3 step 1 built 2026-10-03 (Ship upgrade hangar thread). The full design Eric approved is the doc "Hangar Redesign: Slots, Combos and Upgrade Tree" (https://claude.ai/code/artifact/28501082-1279-4104-9dd3-e3d3fa056c6f). Build order (Eric): 1 base ship slots and placement (this), 2 combos and the rest of the parts catalog, 3 one upgrade tree per ship. All numbers are data in `data/hangar/` and `data/medals/`.

## Economy
- **Scrap** is the currency (shown as SCRAP; saved as `currency`). Destroyed ships leave scrap piles, and **stage medals** (one optional goal per stage, `StageDef.medal`) pay a scrap bonus once per run. Both scale by `DifficultyDef.score_multiplier` and the `scrap_mult` stat.
- Scrap buys **parts** and their **ranks** in the store. Each part has ranks 1-3; rank 1 costs the tier price (Starter is free), rank 2 the same again, rank 3 twice that (`PartDef.TIER_COST`: Starter 60, Common 100, Uncommon 200, Rare 400, Epic 800).

## The ship (ShipDef)
The Kestrel (base ship) has one slot each of **weapon, shield, power and bonus**. The weapon sits on the **nose**. The other three go on the **left, rear and right** mounts in any order the player picks. Engines, extras and (later) chips share the bonus slot. Advanced ships with more slots come from the upgrade tree (step 3).

## Placement (Eric picked "mild asymmetry")
Where a part sits adds the effects in `HangarCatalog.placement`:

| Part | Left | Rear | Right |
|---|---|---|---|
| Engine | +25% strafe right | +15% speed | +25% strafe left |
| Shield | recharge 20% faster | normal | recharge 20% faster |
| Power, extra | look only (for now) | look only | look only |

Stats: `strafe_left` / `strafe_right` scale horizontal speed in `Player` (keyboard and touch).

## Parts (PartDef)
Categories: weapon (green), shield (purple), power (yellow, the C/L / pad Y / FREEZE button), engine and extra (blue), chip (step 2). Effects carry an optional `rank` key: they apply once the part reaches that rank.

| Category | Parts built in step 1 |
|---|---|
| Weapons | Pulse Laser (starter), Twin Cannon, Needle Gun, Missile Pod |
| Shields | Bubble (starter), Regen Field, Ablative Armor |
| Powers | Cryo Pulse (starter) |
| Engines | Ion Thruster (starter), Vector Jet |
| Extras | Scrap Magnet (starter, free to buy), Scrap Compactor, Drone Bay, Combo Amp |

A new save flies Pulse Laser (nose), Bubble (left), Ion Thruster (rear) and Cryo Pulse (right). Saves from the materia hangar keep their pilots and start this fresh loadout.

## Ship visuals
Every fitted part draws its pixel sprite at its mount, sticking out past the hull. Rank 2 adds a glow in the slot color; rank 3 doubles the part. Drawn by `assets/art/dusk_armada/ship_parts.gd` (its `preview` property draws any loadout for the store).

## Menu
Title > HANGAR: ship preview, then PILOT, LOADOUT (pick a mount, then a part; the preview shows the result before you choose) and STORE. The store (`scenes/main/hangar_store.gd`) has six category tabs; each card shows your ship wearing that part. A card opens NOW / AFTER previews, the look of each rank, what each rank does, BUY / RANK UP, and FIT TO SHIP. Cancel goes back one level.

## Pilots
Picked on the hangar's PILOT page. Each pilot brings one active power on its own button (SHIFT/X/K, gamepad B/X, or a two-finger tap), separate from the ship's Power slot (Eric kept two buttons).

| Pilot | Power | Effect | Recharge | Cost |
|---|---|---|---|---|
| Vega | Overclock | 2.5x fire rate and +1 shot for 5s | 20s | free |
| Rook | Bulwark | shield back up, untouchable for 3s | 25s | 250 |
| Nyx | Phase Dash | blink 170 px in the move direction, untouchable mid-dash | 6s | 400 |
| Juno | Nova | clears enemy shots, 2 damage to every enemy | 30s | 600 |

Data: `data/hangar/pilots/` (`PilotDef`), run by `scenes/player/pilot_power.gd`.

## Next
- Step 2: chips and FF7-style combos (base + element + pattern, named secret combos), parts that add combo sockets, and the rest of the catalog (Wave Gun, Flak Burst, Saw Disc, Plasma Orb, Rail Driver, the other shields, powers, engines and extras). The Power slot then needs a general ship-power runner beside the freeze system.
- Step 3: one upgrade tree per ship; Talon, Bastion and Seraph unlock from it (their hull sprites are already in `assets/art/dusk_armada/`).
- Medals for stages 4 to 10 (M5).
