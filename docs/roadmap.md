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
- [ ] Push to GitHub repo; enable Pages (Settings > Pages > Source: GitHub Actions)
- [ ] Confirm CI green and web build loads in browser

## M1 Core loop slice
- [ ] Input actions (keyboard, gamepad, touch)
- [ ] Player ship: move, shoot (pooled bullets)
- [ ] One enemy type with Health/Hitbox components
- [ ] Score, lives, HUD, game over, restart

## M2 Galaga feel
## M3 Upgrades v1
## M4 Difficulty + meta
## M5 Sector 1 complete
## M6 Art + audio pass
## M7 Content scale
## M8 Release polish
