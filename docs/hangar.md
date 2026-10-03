# Hangar: ship slots, parts, placement and the store

Status: v3 step 1 built 2026-10-03, then slot menus, attributes, rotating stock and the blueprint tree (Eric picked mockups A and T3, https://claude.ai/artifact/NUp3X27ErZGbXTutw4MiZy). The full design Eric approved is the doc "Hangar Redesign: Slots, Combos and Upgrade Tree" (https://claude.ai/code/artifact/28501082-1279-4104-9dd3-e3d3fa056c6f). Build order (Eric): 1 base ship slots and placement (this), 2 combos and the rest of the parts catalog, 3 one upgrade tree per ship. All numbers are data in `data/hangar/` and `data/medals/`.

## Economy
- **Scrap** is the currency (shown as SCRAP; saved as `currency`). Destroyed ships leave scrap piles, and **stage medals** (one optional goal per stage, `StageDef.medal`) pay a scrap bonus once per run. Both scale by `DifficultyDef.score_multiplier` and the `scrap_mult` stat.
- Scrap buys **parts** from the store's rotating stock (`PartDef.TIER_COST`: Starter 60, Common 100, Uncommon 200, Rare 400, Epic 800), **attribute levels** (level N costs N x `PartDef.LEVEL_COST`: 30, 50, 80, 120, 180 by rarity) and **blueprint node ranks** (rank N costs N x the node's cost).

## Store stock (HangarStock)
5 parts you don't own, rolled with weights 6/6/4/2/1 by rarity. New stock after every run, or now for 40 scrap (REROLL). Each card shows your ship wearing the part.

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
Categories: weapon (green), shield (purple), power (yellow, the C/L / pad Y / FREEZE button), engine and extra (blue), chip (step 2). Base `effects` apply while fitted; each **attribute** has its own max level and applies its effects once per level.

| Category | Parts (rarity) and attributes |
|---|---|
| Weapons | Pulse Laser (starter: POWER, SPEED, THICKNESS), Twin Cannon (common: POWER, FIRE RATE, BARRELS), Needle Gun (uncommon: POWER, FIRE RATE, PIERCE), Missile Pod (rare: RELOAD, SALVO, HOMING), Arc Lance (epic: POWER, SPEED, ARC) |
| Shields | Bubble (starter), Regen Field, Ablative Armor (common), Prism Shield (rare: LAYERS, RECHARGE, SHOCK) |
| Powers | Cryo Pulse (starter: DURATION, CHARGES) |
| Engines | Ion Thruster (starter), Vector Jet (common), Phase Engine (rare: THRUST, WINDOW) |
| Extras | Scrap Magnet (starter), Scrap Compactor, Drone Bay (common), Combo Amp (uncommon), Spare Hull (rare: +1 ship per run; SHIPS +1 more per level, max 2) |

## Blueprint tree (ShipTree, TreeNodeDef)
Each ship has a blueprint: nodes sit on a mount (or the hull) and boost the ship. A node opens only when the part fitted on its mount is at least its rarity, so rarer parts open deeper nodes there. Swap in a lower-rarity part and those nodes go dark (ranks are kept). Kestrel: NOSE Focus Lens, Rail Coil (uncommon), Hunter Core (rare), Twin Rail (epic); LEFT Plating, Capacitor (uncommon), Shock Plate (rare); REAR Afterburn, Slip Jets (uncommon), Overdrive Core (rare); RIGHT Salvage Rig, Tractor (uncommon), Chrono Cell (rare); HULL Combo Wiring.

A new save flies Pulse Laser (nose), Bubble (left), Ion Thruster (rear) and Cryo Pulse (right). Saves from the materia hangar keep their pilots and start this fresh loadout.

## Ship visuals
Every fitted part draws its pixel sprite at its mount, sticking out past the hull. 4+ attribute levels add a glow in the slot color; 9+ double the part (`Loadout.look`). Drawn by `assets/art/dusk_armada/ship_parts.gd` (its `preview` property draws any loadout for the store).

## Menu
Title (or game over) > HANGAR: the ship, then one row per slot (part and attribute levels), STORE, BLUEPRINT, PILOT. A slot opens its categories (the nose goes straight to weapons), a category its parts (owned, in stock with price, or not in stock), and a part its attributes: each row shows level pips and the next level's price, and pressing it upgrades. Then FIT TO <slot> (a part of the same slot type elsewhere comes off), BUY when stocked, BACK. The blueprint shows the ship on a grid with ranks per mount, then each mount's part and rarity above its nodes. Code: `scenes/main/hangar.gd`, `hangar_parts.gd`, `hangar_blueprint.gd`. Cancel goes back one level.

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
- Step 3: blueprints for Talon, Bastion and Seraph, and capstones that unlock those ships and a 5th slot (their hull sprites are already in `assets/art/dusk_armada/`).
- Medals for stages 4 to 10 (M5).
