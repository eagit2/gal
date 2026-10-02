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
- [ ] StyleDirector + style switch with placeholder visuals for both styles
- [ ] Spike: outrun grid shader + glow on web build
## M3 Upgrades v1
- [ ] ComboTracker + ComboDef: Overdrive mode end to end (meter, buff, N1 style switch)
- [ ] Remaining combo modes (Lock-On, Chain Reaction, Graze), Style Chain, Arcade '81 on rescue
## M4 Difficulty + meta
## M5 Sector 1 complete
## M6 Art + audio pass
## M7 Content scale
## M8 Release polish
