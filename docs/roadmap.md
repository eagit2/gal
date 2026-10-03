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
- [ ] Playtest in browser and tune feel

## M3 Upgrades v1
- [ ] Upgrade drops: DropTable per enemy, pity bonus, falling pickup (adds to the card pick)
- [ ] ComboTracker + ComboDef: Overdrive mode end to end (meter, buff, N1 style switch)
- [ ] Remaining combo modes (Lock-On, Chain Reaction, Graze), Style Chain, Arcade '81 on rescue
## M4 Difficulty + meta
- [ ] Stage medals (goal per stage) pay meta currency, scaled by difficulty
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
## M7 Content scale
## M8 Release polish
