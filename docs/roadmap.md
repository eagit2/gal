# Roadmap

Each milestone ends with a playable web build. See `architecture.md` section 8.

## M0 Project setup
- [x] Godot 4.5 project, Compatibility renderer, 540x960 portrait
- [x] Folder skeleton per architecture
- [x] Autoloads stubbed: EventBus, GameState, SaveManager, AudioManager, SceneRouter, Pools
- [x] Content Resource classes (EnemyDef, WaveDef, StageDef, SectorDef, BossDef, UpgradeDef, SynergyDef, WeaponDef, DifficultyDef, ThemeDef)
- [x] Boot and title scenes
- [x] Headless test runner + first tests
- [x] Web export preset (single-threaded)
- [x] CI workflow: test, export, publish to GitHub Pages
- [x] Push to GitHub repo
- [x] CI green (tests + web export)
- [x] Pages enabled; deploy succeeds (https://eagit2.github.io/gal/)

## M1 Core loop slice
- [x] Input actions (keyboard, gamepad, touch)
- [x] Player ship: move, shoot (pooled bullets), invulnerability after respawn
- [x] One enemy type (bee) with Health/Hurtbox/Hitbox components, swaying grid, aimed shots
- [x] Score, lives, HUD, pause, game over, restart, high score saved
- [x] Waves repeat with rising aggression
- [x] Headless smoke playthrough in CI
- [x] Playtest in browser (Eric: movement, fire rate, shooting OK; ship can now fly to the top)

## M2 Galaga feel
- [x] Ramming an enemy destroys it (and costs a life)
- [x] Entry paths as data (`data/paths/*.tres`), fly to formation slot
- [x] Formation sways while waves enter, then breathes
- [x] Dives (DiveController + generated dive curves), aimed shots during dives, return from top
- [x] 3 enemy types: bee, moth (zigzag dive), warden (2 hits, wide dive); double score mid-dive. Names follow design/intro-levels.md
- [x] Stage 1 and 2 from data (40 enemies each); sector_1 loops with rising aggression
- [x] Challenging stage: fly-through waves, no shots, hit bonus + perfect bonus
- [x] StyleDirector + style switch with placeholder visuals for both styles (F2 debug toggle; challenge stage forces Outrun)
- [x] Spike: outrun grid shader with in-shader glow, renders on the Compatibility renderer
- [x] Playtest in browser (Eric: controls fine; pacing needs to be frantic, add a shield, enemies need their own logic)

## M2.5 Intensity pass (playtest feedback)
- [x] Enemy brains replace fixed dive paths: swarmer (bee, homing kamikaze, re-attacks), strafer (moth, shadows the player and fires bursts, may commit), hunter (warden, leads escorts, spread shots, rams when hurt), escort
- [x] Squad attacks start 2s into a stage, up to 3 at once; cap scales with difficulty and aggression (3 to 12); formation fire
- [x] More volume: waves arrive ~45% faster; reinforcement squads fill empty slots (stage 1: +3, stage 2: +4)
- [x] Auto shield bubble: absorbs one shot or ram, recharges (DifficultyDef.shield_recharge, 9 to 16s)
- [x] Playtest (Eric, 2026-10-03): speed, shield and enemy logic all good as is

- [x] Playtest shortcuts: URL options to start on any stage, god mode, repeat, difficulty

## M3 Upgrades v1
- [x] Run stats from upgrades + synergies + active combo (`UpgradeSystem`, `GameState.stats`)
- [x] 19 upgrades across 4 categories, stacking, requirements; 3 synergies (Swarm, Storm Front, Detonator)
- [x] Card pick (1 of N per difficulty) after every stage; keyboard, gamepad, touch
- [x] Weapon stats: extra shots, spread, pierce, homing, damage, shot speed; missiles and wing drones; layered shield
- [x] Upgrade drops: per-enemy chance, pity bonus, rarity bonus, falling pickup, magnet; perfect challenge drop
- [x] ComboTracker + ComboDefs: Overdrive, Lock-On, Chain Reaction (kill blasts), Graze (slow-mo + graze score), Arcade '81 (fires on `ship_rescued`, which M5 capture emits)
- [x] Style Chain multiplier, meter decay, HUD meters and mode timer
- [x] Styles: Cold Hologram, Particle Storm, Pocket Four (post shader), Arcade Classic+ (post shader + starfield)
- [ ] Playtest and tune: drop rate, meter thresholds, upgrade values
- [x] M3.5 upgrade rework: drops change bullets only, cards are utility (Cryo Pulse freeze, extra bubbles, credit multiplier), lower values
- [x] M3.6 no between-stage pick: utility upgrades drop as gold capsules
- [x] M3.7 scrap economy (drops are hangar currency), elites with traits, capture and dual fighter, combos keep the screen
- [x] M3.8 enemy roster batch 1 (design/enemy-roster.md): falling rocks crush enemies, Blinker, Dasher, Rock Dropper, Puppeteer, Phase Stalker, Hive Carrier; 1 ship per run plus Spare Hull part; Hangar from game over
- [x] M3.9 enemy roster batch 2: Splitter, Plated, Mender, Mine Layer, Mimic, Meteor Caller, Mirror Knight, Gravity Well, Twin Sentinels, Sweeper; per-stage HP multiplier plus a ramp each loop; random elite pools per stage
- [x] M3.11 roster expansion from the Roster Tuning artifact: 21 new traits (blade slash, fire bar, slot jam, evolve, flagship, scrap thief, hard hat, wind gust, boomerang, spawner pipe, gravity pool, blade release, orbit guard, decoy, reflect shield, weakness, copy weapon, time stop, scatter body, leaf shield, multi part), 10 new enemies, 9 new elites, 2 new bosses, elite levels 1 to 4, stage 3
- [x] M3.13 easy tier: 20-stage Sector 1 (own easy stages 1-10, hp about half, 3 elites; the old 1-10 are 11-20), elite levels L1-L5 (new easy L1, old base is L2), sweep arc 20 degrees, per-stage `dive_aggression` and `kamikaze_speed` (+0.3 per loop)
- [x] M3.12 aggression pass and the 10-stage Sector 1: elites and bosses fire about twice as often with wider fans, cooldowns x0.6, `chase` patrol bias; stages 3 to 10 built from the Roster Tuning plan (mini-bosses at 5 and 8, The Matriarch at 10, hp x1.0 to x3.0, elite levels open at stages 1/3/6/9)
- [x] M3.10 roster sheet: data/roster/*.csv for enemies, elites and bosses (numbers, looks, trait mixes, boss phases), ?spawn= test option, draft Matriarch boss row
## M4 Difficulty + meta
- [x] Hangar v2 (materia style): 4 frames with linked slots, 21 modules that level from AP, mastery copies and upgrade chains, ship parts per module, deeper menu (`docs/hangar.md`)
- [x] Pilots with powers: Dave (Overclock), Rook (Bulwark), Chere (Phase Dash), Juno (Nova)
- [x] Pilot powers and Cryo Pulse fire on their own; controls are steer and fire only
- [x] Hangar v3 step 1: typed slots on nose/left/rear/right mounts, placement effects, 14 ranked parts, categorized store with ship previews (`docs/hangar.md`)
- [x] Hangar v3 slot menus (Eric picked mockups A and T3): slot > category > part > attribute upgrades, rotating store stock, Kestrel blueprint tree gated by part rarity, 18 parts (`docs/hangar.md`)
- [x] Hangar cleanup: round upgrade numbers shown in real units, ship-specific skill tree (3 branches), cleaner cards on every hangar screen
- [x] Hangar round 2: ships menu with unlocks, slimmer slot menu, part dropdown, link sockets on parts and store, forked Kestrel tree
- [x] Hangar round 3: chips and link combos, per-weapon shots, shields only when fitted, owned-only lists with quick equip, 3-item store
- [x] Design-board weapons: Flak Cannon, Rail Spike, Scrap Cannon, Twin Needle, Mine Launcher, Rubber Duck Gun, Bubble Blower (`docs/hangar.md`)
- [x] Weapon pass 2: duck/bubble/scrap tweaks; Ball Lightning, Hypno Gun, Gravity Gun (`docs/hangar.md`)
- [ ] Hangar v3 step 2b: rest of the parts catalog
- [ ] Hangar v3 step 3: ship trees for Talon, Bastion and Seraph, and tree capstones that unlock ships and a 5th slot
- [x] Title screen: Continue (resumes the saved run at its last stage), New Game with difficulty pick and an overwrite confirm. Hangar button hook in `title.gd`.
- [x] 3 save slots with autosave (new games start with 5000 scrap; settings shared), slot picker for New Game / Continue / Load, game over menu (Restart level, Hangar, Load, Options, Quit to menu or game).
- [x] Stage medals (goal per stage) pay meta currency, scaled by difficulty (v1 goals on stages 1, 2 and challenge 1)
## M5 Sector 1 complete
Spec: `/mnt/project-files/design/intro-levels.md` (approved by Eric).
- [ ] 10 stages: 1 First Contact, 2 Captured, 3 Challenge, 4 Fuse Line, 5 Crossfire, 6 Rain of Rings, 7 Challenge, 8 Shield Wall, 9 The Long Approach, 10 Boss: The Matriarch
- [ ] New enemies: Fusewing, Lancer, Spinner, Shieldbearer; Moth loop-dive with 2-shot burst; Warden tractor beam + escorts
- [ ] Tractor beam capture and dual fighter
- [ ] The Matriarch boss: unique attacks and mechanics, including card theft
- [ ] Stage intro titles, medals per stage
## M6 Art + audio pass
- [x] Dusk Armada base sprites: player, 7 Sector 1 enemies, shots, pickup, explosion, sunset sky with cloud sea (`tools/art/gen_dusk_armada.py`)
- [x] Damage feedback: hit flash, shake, sparks, damaged frames + smoke, debris explosions, player death explosion
- [x] Energy shots: glowing tracers with muzzle flash, plasma orbs
- [x] Shield bubble art with absorb flash, shatter on pop and grow-in on recharge (`shield.tscn`, ready for the shield in m2.5)
- [ ] The Matriarch boss art
- [ ] Combo style treatments: P1 and P3 palette shaders, N2 and N3 vector looks
- [x] Audio system: SoundBank data, AudioManager crossfades and voice priority, AudioCues on EventBus, mute key
- [x] 19 generated SFX (shots, hits, explosions, shield pop/restore, graze, combos, jingles, UI) and 8 music loops (title, stage, boss, 5 combo styles) (`tools/audio/`)
- [x] Combo-style tracks wired into the M3 ThemeDefs
- [x] Sector 1 soundtrack: a track per stage group plus mini-boss and Matriarch themes (`StageDef.music`)
- [ ] Adaptive music layers (stems by intensity), classic SFX set for Arcade '81
## M7 Content scale
- [ ] Consider: in-game level editor scene (place waves visually, press play to test)
## M8 Release polish
