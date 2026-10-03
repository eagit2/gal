# Hangar: ship slots, parts, placement and the store

Status: v3 step 1 built 2026-10-03, then slot menus, attributes, rotating stock and a ship tree (first gated by part rarity, then made ship-specific) (Eric picked mockups A and T3, https://claude.ai/artifact/NUp3X27ErZGbXTutw4MiZy). The full design Eric approved is the doc "Hangar Redesign: Slots, Combos and Upgrade Tree" (https://claude.ai/code/artifact/28501082-1279-4104-9dd3-e3d3fa056c6f). Build order (Eric): 1 base ship slots and placement (this), 2 combos and the rest of the parts catalog, 3 one upgrade tree per ship. All numbers are data in `data/hangar/` and `data/medals/`.

## Economy
- **Scrap** is the currency (shown as SCRAP; saved as `currency`). Destroyed ships leave scrap piles, and **stage medals** (one optional goal per stage, `StageDef.medal`) pay a scrap bonus once per run. Both scale by `DifficultyDef.score_multiplier` and the `scrap_mult` stat.
- Scrap buys **parts** from the store's rotating stock (`PartDef.TIER_COST`: Starter 60, Common 100, Uncommon 200, Rare 400, Epic 800), **attribute levels** (level N costs N x `PartDef.LEVEL_COST`: 30, 50, 80, 120, 180 by rarity) and **ship tree ranks** (rank N costs N x the node's cost).

## Store stock (HangarStock)
3 items: parts you don't own (weights 6/6/4/2/1 by rarity) and chips (weight 2, `HangarStock.CHIP_WEIGHT`). New stock after every run, or now for 40 scrap (REROLL). Each card shows your ship wearing the part.

## The ship (ShipDef)
Three ships: Kestrel (open), Talon (clear stage 5) and Bastion (beat the Matriarch, stage 10); `ShipDef.unlock_stage`, with cleared stages saved in the loadout state (`cleared`). Each has its own tree (Talon and Bastion trees come later). Slots per ship (`ShipDef.slots`): 2 weapons, 1 shield, 1 engine, 2 extras. The nose takes a weapon; the left, rear and right mounts take any part, a second weapon too (Eric, mockup 2b).

## Placement (Eric picked "mild asymmetry")
Where a part sits adds the effects in `HangarCatalog.placement`:

| Part | Left | Rear | Right |
|---|---|---|---|
| Engine | +25% strafe right | +15% speed | +25% strafe left |
| Shield | recharge 20% faster | normal | recharge 20% faster |
| Weapon, extra | look only (for now) | look only | look only |

Stats: `strafe_left` / `strafe_right` scale horizontal speed in `Player` (keyboard and touch).

## Parts (PartDef)
Categories in the slot menu: weapons (green), shields (purple), engines (blue), extras (yellow). Powers folded into extras (Cryo Pulse is an extra now; `Category.POWER` stays only so saved numbers keep meaning). Chips come with combos. Base `effects` apply while fitted; each **attribute** levels on its own. Every part has **link sockets** (`sockets`, `links` = linked pairs): Starter and Common 1, Uncommon 2 (linked), Rare 3 (a linked pair + 1), Epic 4 (two linked pairs). Chips go in them once combos land; the ship tree can add more (`Loadout.sockets`).

| Category | Parts (rarity) and attributes |
|---|---|
| Weapons | Pulse Laser (starter: POWER, SPEED, PENETRATION), Twin Cannon (common: POWER, FIRE RATE, BARRELS), Needle Gun (uncommon: POWER, FIRE RATE, PIERCE), Missile Pod (rare: RELOAD, SALVO, HOMING), Arc Lance (epic: POWER, SPEED, ARC) |
| Weapon shots | Each weapon fires its own `WeaponDef` (data/weapons): Pulse Laser 8/s, 1 dmg cyan bolt; Twin Cannon 3/s, two parallel 2-dmg orange rounds 14 px apart; Needle Gun 11/s, fast (1350) thin green darts; Missile Pod 2/s, a pair of 3-dmg homing missiles; Arc Lance 3.5/s, 4-dmg violet beam-bolt piercing 3. Nose fires straight; a weapon on a side mount fires its own shot 15° outward, on the rear straight up (`systems/ship_guns.gd`). Empty nose = basic gun. Run stats modify every gun. |
| Shields | Bubble (starter), Regen Field, Ablative Armor (common), Prism Shield (rare: LAYERS, RECHARGE, SHOCK) |
| Engines | Ion Thruster (starter), Vector Jet (common), Phase Engine (rare: THRUST, WINDOW) |
| Extras | Cryo Pulse (starter: DURATION, CHARGES), Scrap Magnet (starter), Scrap Compactor, Drone Bay (common), Combo Amp (uncommon), Spare Hull (rare: +1 ship per run; SHIPS +1 more per level, max 2) |

## Ship tree (ShipTree, TreeNodeDef)
Each ship has its own skill tree (Eric, mockup 6b: "plan is good"). Drawn as a map: the ship at the bottom, three branches (offense, defense, utility) growing up. **Forks** (`excludes`, shown OR): buying one side closes the other. **Merges** (diamonds) need both parents. **Capstones** (circles) need any `needs` of the row below, and fork too. Socket nodes add a link socket to every part of a category (`socket_category`). Ranks cost scrap (rank N = N x cost).

Kestrel: Focus Lens (+5% fire rate, 3) > Scatter (3-way spread) OR Rail (pierce 2, +30% shot speed); Plating (recharge 5% faster, 3) > Reflect (shield bounces bullets) OR Absorb (shield hits fill the combo meter); Afterburn (+5% speed, 3) > Drone Drift (2 drones, 10% slower) OR Blink (dash teleports). Swarm Link (after Scatter, +1 weapon socket), Ricochet (Rail + Reflect: reflected shots fire as rails), Overflow (Absorb + Drone Drift: combo modes 50% longer), Phase Link (after Blink, +1 engine socket). Capstone, any 2 of those: Armada (start each stage with a wingman) OR Lone Wolf (+1 damage, combo meters fill twice as fast). Reflect, Absorb, Blink, Ricochet and Armada are stats the run doesn't read yet (`shield_reflect`, `shield_combo`, `blink`, `ricochet`, `wingman`; plan phase 6).

## Ship visuals
Every fitted part draws its pixel sprite at its mount, sticking out past the hull. 4+ attribute levels add a glow in the slot color; 9+ double the part (`Loadout.look`). Drawn by `assets/art/dusk_armada/ship_parts.gd` (its `preview` property draws any loadout for the store).

## Menu
Title (or game over) > SHIPS (locked ships greyed with their unlock) > the ship's HANGAR: the ship with a box per slot around it, then STORE, SHIP TREE, PILOT, < SHIPS. A slot opens WEAPONS / SHIELDS / ENGINES / EXTRAS / < BACK (the nose goes straight to weapons). A category lists only owned parts; the highlighted one opens in place with level bars, final numbers and filled link sockets, plus EQUIP ON <mount> (or EQUIPPED ON) and UPGRADE AND LINKS rows. The part screen says EQUIPPED ON <mount> / NOT EQUIPPED, then attribute upgrade cards, LINKS (opens the chip screen, `hangar_chips.gd`: pick a socket, pick an owned chip), and a COMBO row for each active combo. Store cards show rarity, category, sockets and price. Code: `scenes/main/hangar.gd`, `hangar_parts.gd`, `hangar_tree.gd`, `ui/hangar_cards.gd`. Cancel goes back one level.

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
- Step 3: ship trees for Talon, Bastion and Seraph, and capstones that unlock those ships and a 5th slot (their hull sprites are already in `assets/art/dusk_armada/`).
- Medals for stages 4 to 10 (M5).

## Chips and link combos
8 chips (`data/hangar/chips/`, 150 scrap each, bought from the store, owned as counts): Power, Rapid, Split, Seeker, Pierce, Ember (burn), Frost (chill), Volt (chain). Each socketed chip adds its effects. Two specific chips in a linked socket pair make a combo (`data/hangar/combos/`, 10 of them, e.g. Ember + Power = Inferno) that adds its own effects. Combos show only when active.
