# Modern Galaga: Development Architecture

Status: proposal, 2026-10-02. Engine and platform decided (Godot, browser). Portrait. Two art styles switched at runtime (Dusk Armada pixel base + Outrun Grid neon), see section 6.

---

## 1. Design pillars (what every decision serves)

1. **Readable chaos.** Dense bullets and swooping enemies, but the player always knows what killed them. Hitboxes small, telegraphs clear.
2. **Build-crafting.** Every run feels different because of upgrade choices. Upgrades combine (synergies), not just stack numbers.
3. **Escalation with variety.** Each stage adds one new idea (enemy, pattern, hazard, modifier) instead of only more HP.
4. **Fair difficulty, player-chosen.** Difficulty changes tuning numbers and a few rules, never the content you get to see.
5. **Short sessions.** A run is 15 to 25 minutes; a stage is 60 to 120 seconds. Fits the browser.

## 2. Core game design

### 2.1 Core loop
```
Title > Difficulty select > Hangar (spend meta currency) > Run
Run:  Stage (enemies may drop upgrades) > Upgrade pick (1 of 3) > Stage > ... > Boss > Sector clear > next Sector
Medals earned in stages pay meta currency
Death or win > Results (score, currency earned) > Hangar
```

### 2.2 Classic Galaga mechanics to keep
- Enemies fly in on scripted paths, settle into a **formation** grid that breathes (expands/contracts).
- Enemies leave formation to **dive** at the player, then return or loop off screen.
- **Boss tractor beam** captures the ship; rescuing it gives a **dual fighter** (2x firepower, 2x hitbox). Keep it; it is the signature risk/reward.
- **Challenge stages** (no enemy fire, score bonus for perfect clears) every 3rd stage.

### 2.3 Modern additions
- **Two-layer upgrades**
  - *In-run (roguelite):* after each stage, choose 1 of 3 upgrade cards. Kills can also **drop upgrade pickups** during a stage (per-enemy `DropTable` chance, a pity bonus that grows with each dry kill, rarity rolled like cards, scaled by difficulty). Drops add to the card pick; they don't replace it. Lost on death. Details: `/mnt/project-files/design/intro-levels.md` section 2.1.
  - *Meta (persistent):* currency comes from **stage medals** (an optional goal per stage, paid the first time it's earned each run, scaled by difficulty). It buys permanent hangar unlocks (new ships, starting perks, new upgrades added to the card pool). Unlocks widen options more than they add raw power.
- **Upgrade categories:** Primary weapon (spread, laser, homing, piercing), Secondary (missiles, drones, bombs), Defense (shield, armor, dodge-dash), Utility (magnet, score multiplier, slow-mo on graze), Synergies (unlocked when two tagged upgrades are owned, e.g. *Homing + Missiles = Swarm*).
- **Rarity tiers** (common/rare/epic) and **tags** drive card weighting and synergies.
- **Sectors** (worlds). Sector 1 is the 10-stage onboarding sector (9 stages + boss, challenges at 3 and 7; see `/mnt/project-files/design/intro-levels.md`). Later sectors default to 5 stages + boss. Each sector has a theme and a mechanical twist (asteroid fields, gravity wells, shielded formations, darkness/limited vision, mirrored enemies).
- **Stage modifiers** on later sectors and higher difficulty (enemies split on death, faster dives, armored front row).
- **Boss fights** with phases and weak points, distinct from the formation game.

### 2.4 Difficulty
Selectable at run start. Implemented as data (`DifficultyProfile`), never `if hard:` branches in code.

| Knob | Cadet | Pilot | Ace | Nightmare |
|---|---|---|---|---|
| Enemy bullet speed | 0.7x | 1.0x | 1.25x | 1.5x |
| Dive frequency | 0.6x | 1.0x | 1.3x | 1.6x |
| Enemy HP | 0.8x | 1.0x | 1.2x | 1.5x |
| Lives | 5 | 3 | 3 | 1 |
| Upgrade choices | 4 | 3 | 3 | 2 |
| Stage modifiers | none | sector 3+ | sector 2+ | always |
| Score / currency mult | 0.75x | 1.0x | 1.5x | 2.5x |

Optional later: light dynamic assist on Cadet only (slightly fewer bullets after repeated deaths).

### 2.5 Controls
Keyboard (arrows/WASD, Space fire, Shift dash, Esc pause), gamepad, and touch (drag to move, auto-fire) since it runs in a browser. Auto-fire toggle in settings.

## 3. Engine and tech choices

- **Godot 4.x (latest stable), GDScript.** Static typing on (`var x: int`) for fewer bugs across sessions.
- **Renderer: Compatibility** (WebGL 2). Required for reliable web export.
- **Web export: single-threaded build** so it runs on any static host (itch.io, GitHub Pages) without special COOP/COEP headers.
- **Fixed internal resolution** (e.g. 270x480 portrait for pixel art or 540x960 for neon), `canvas_items` stretch, `keep` aspect. Decide once art style is picked; logic uses world units so this is a config change.
- **Physics:** Area2D overlap for all hits (no RigidBody). Bullets pooled.
- **Testing:** minimal in-repo runner (`tests/run_tests.gd`) for pure-logic tests: upgrade stacking, difficulty math, wave spawning, save/load.
- **Version control:** a Git repo for the Godot project, CI (GitHub Actions) that runs tests headless and publishes the web build on every push to `main`.

## 4. Code architecture

### 4.1 Principles
- **Data-driven content.** Enemies, waves, stages, upgrades, difficulties, bosses are Godot `Resource` files (`.tres`). Adding content means adding data, not code.
- **Logic separate from visuals.** Each entity scene has a logic root (movement, hitbox, health) and a swappable `Visual` child. Changing art style swaps visuals only.
- **Signals over references.** Systems talk through an `EventBus` autoload (e.g. `enemy_killed(enemy, pos)`), so systems can be built and tested in isolation.
- **Components** for shared behavior: `Health`, `Hitbox`, `Hurtbox`, `Shooter`, `PathFollower`, `DropTable`.
- **Small files.** One scene + one script per concept; target under 300 lines per script so any session can read a whole system quickly.

### 4.2 Autoloads (singletons)
| Autoload | Responsibility |
|---|---|
| `EventBus` | Global signals only, no state |
| `GameState` | Current run: score, lives, stage index, owned upgrades, difficulty |
| `SaveManager` | Meta progress and settings, `user://save.json`, versioned schema (browser stores it in IndexedDB) |
| `AudioManager` | Music layers, pooled SFX players, bus volumes |
| `SceneRouter` | Scene transitions with fades |
| `Pools` | Object pools for bullets, particles, pickups |

### 4.3 Key systems
- **WaveDirector:** reads a `StageDef`, spawns `WaveDef`s on a timeline, assigns each enemy an entry `Path2D` and a formation slot.
- **Formation:** grid of slots that sways and breathes; tracks which slots are filled.
- **DiveController:** sends squads of formation enemies to attack based on difficulty dive rate, stage aggression, and how many are already attacking; also fires from the formation.
- **Enemy brains:** each EnemyDef points at an `EnemyBrain` resource (`scenes/enemies/behaviors/`, data in `data/brains/`) that steers the attack live (turn-rate-limited steering, lead aiming, separation). Brains are shared, so per-enemy state lives on the Enemy.
- **UpgradeSystem:** applies `UpgradeDef` effects to a `PlayerStats` object via modifiers (add, multiply, flag); computes synergies from tags; rolls card choices and drop rarities with the same weights and pool unlocks.
- **DropSystem:** on `enemy_killed`, rolls the enemy's `DropTable` (with pity bonus and `DifficultyDef.drop_mult`) and spawns a slow-falling pickup the ship collects by flying over it.
- **MedalTracker:** watches the stage's medal goal (`StageDef.medal`) and pays `medal_currency` into `SaveManager` once per run.
- **WeaponSystem:** a weapon is a `WeaponDef` (fire rate, pattern, projectile scene); upgrades modify it rather than replacing code.
- **BossController:** phase state machine driven by `BossDef` (phases, HP thresholds, attack patterns).
- **CaptureSystem:** tractor beam, captured ship, rescue, dual fighter.

### 4.4 Content data types
```
EnemyDef       id, hp, score, speed, visual_scene, brain, drop_table
WaveDef        enemy_id, count, entry_path, formation_slots, delay
StageDef       id, waves[], is_challenge, modifiers[], music_intensity
SectorDef      id, name, theme, stages[], boss
BossDef        id, phases[] (hp_threshold, attacks[], movement)
UpgradeDef     id, name, description, rarity, tags[], max_stacks, effects[], requires[]
SynergyDef     id, required_tags[], effects[]
DifficultyDef  id, multipliers{}, lives, card_count, modifier_rules, drop_mult, currency_mult
DropTable      chance, rarity_bonus   (on EnemyDef)
StageDef       + medal (goal id), medal_currency
ThemeDef       palette, background_scene, particle_set, music_set   (art-style hook)
```

## 5. File structure

```
modern-galaga/                      (Git repo)
├─ project.godot
├─ export_presets.cfg               (Web preset committed)
├─ README.md                        how to run, test, export
├─ CLAUDE.md                        rules for AI sessions (points to docs/)
├─ addons/                          gdUnit4, other plugins
├─ autoload/                        event_bus.gd, game_state.gd, save_manager.gd, audio_manager.gd, scene_router.gd, pools.gd
├─ scenes/
│  ├─ main/                         boot, title, difficulty_select, hangar, results
│  ├─ game/                         game.tscn (stage host), hud, pause_menu, upgrade_pick
│  ├─ player/                       player.tscn, player.gd, ships/
│  ├─ enemies/                      base_enemy.tscn, behaviors/, bosses/
│  ├─ projectiles/                  bullet, laser, missile
│  ├─ components/                   health, hitbox, hurtbox, shooter, path_follower
│  └─ fx/                           explosions, hit flashes, screen shake
├─ systems/                         wave_director, formation, dive_controller, upgrade_system, weapon_system, capture_system
├─ data/                            .tres content only, no scripts
│  ├─ enemies/  waves/  stages/  sectors/  bosses/
│  ├─ upgrades/  synergies/  weapons/
│  ├─ difficulty/  themes/
│  └─ paths/                        entry and dive Path2D curves
├─ resources/                       Resource class scripts (enemy_def.gd, upgrade_def.gd, ...)
├─ assets/
│  ├─ art/<style>/                  sprites, backgrounds, ui per style (pixel/ or neon/)
│  ├─ shaders/                      glow, flash, dissolve, crt
│  ├─ audio/music/                  .ogg
│  ├─ audio/sfx/                    .wav (short) 
│  └─ fonts/
├─ ui/                              theme.tres, reusable widgets
├─ tests/                           unit/ and integration/ (gdUnit4)
├─ tools/                           editor scripts: wave preview, balance csv export
└─ docs/
   ├─ architecture.md               this file
   ├─ game-design.md                mechanics, upgrades list, sectors
   ├─ roadmap.md                    milestones and status
   ├─ decisions.md                  dated decision log (ADR-lite)
   ├─ content-guide.md              how to add an enemy, wave, upgrade
   └─ balance.md                    tuning tables
```
Project-level files outside the repo (shared folder): `handoff-for-next-session.md` at the project root, plus concept art and reference video.

## 6. Graphics (two styles, switched at runtime)

Decided 2026-10-02 (concepts from the Art style concepts thread, https://claude.ai/artifact/4E2e82z6Ss4LiyFTZt6hj1):
- **Base, "Dusk Armada" (concept P2):** 16-bit outlined pixel sprites over a dithered sunset sky with drifting cloud banks. Used for most of the game.
- **Switch, "Outrun Grid" (concept N1):** synthwave wireframe ships over a scrolling perspective grid and a striped sun. Used under specific level conditions.
- **Resolution:** the viewport stays 540x960. Pixel art is authored at 270x480 and scaled 2x with nearest filtering; outrun visuals are drawn at full 540x960 with smooth lines and glow.

- Every entity's look lives in a `Visual` child scene. Each entity ships **one visual per style**: `assets/art/base/...` and `assets/art/outrun/...`. Gameplay code never references sprites directly.
- **StyleDirector** (autoload) owns the active style. It listens to `EventBus` and swaps style with a short transition (flash, scanline wipe, grid rising from the horizon). Entities' `Visual` nodes listen for `style_changed` and swap or crossfade their child visual. Hitboxes never change.
- **Triggers are data**, not code. **Combo modes** (see `docs/combo-styles.md`) each switch to their own style: Overdrive → N1 Outrun Grid, Lock-On → N3 Cold Hologram, Chain Reaction → N2 Particle Storm, Graze → P3 Pocket Four, ship rescue → P1 Arcade Classic+. Stages and boss phases can also force a style (`StageDef.style`, boss phase field). Exact conditions are a game-design decision, tracked in `docs/game-design.md`.
- **ThemeDef per style**: palette, background scene, particle set, post-process (glow on/off), music stem set. Audio swaps with it (synth-heavy stems for outrun).
- **Cost:** P2 gets full sprite work. Neon styles reuse one vector visual per entity, recolored. P1 and P3 are palette or shader treatments of P2 sprites.
- **Outrun look:** perspective grid floor shader scrolling toward the player, sunset gradient sun, magenta/cyan palette, additive glow, trails. Verify `WorldEnvironment` glow on web early (M2 spike); fallback is a cheap bloom shader.
- **Placeholder first:** colored shapes for both styles until art lands, but the style switch itself is built in M2 so it is designed in, not bolted on.
- **Shared juice:** hit flash shader, screen shake, hit-stop (2 to 4 frames on big kills), particles via `CPUParticles2D`, parallax background.
- **Readability rule:** enemy bullets use one reserved high-contrast color family in **both** styles; check contrast against each palette.

## 7. Audio

- **Buses:** Master > Music, SFX, UI. Volumes in settings, saved.
- **Formats:** music `.ogg` (looping), SFX `.wav` (short, low latency on web).
- **AudioManager:** pooled `AudioStreamPlayer`s, per-sound cooldown and pitch variance to avoid machine-gun repetition, priority so explosions beat shots.
- **Adaptive music:** each track has stems (base, drums, lead); intensity layers fade in with enemy count, boss phase, low lives.
- **Web caveat:** browsers block audio until first input; the title screen "Press to start" unlocks it.
- **Generated:** all SFX and music are synthesized by `tools/audio/` (original, no licensing). Data: `data/audio/sound_bank.tres` (`SoundBank`, `SfxDef`), `ThemeDef.music` per style. `AudioCues` maps EventBus signals to sounds.

## 8. Iterations (milestones)

Each milestone ends with a **playable web build** and a short playtest note. Gameplay first, art last.

| # | Milestone | Exit criteria |
|---|---|---|
| M0 | Project setup | Repo, Godot project, folder skeleton, autoloads stubbed, web export runs in browser, CI runs tests and publishes build |
| M1 | Core loop slice | Ship moves and shoots, one enemy type, enemies die, player dies, lives, score, game over, restart |
| M2 | Galaga feel | Entry paths, formation, dives, 3 enemy types, 1 full stage from data, challenge stage |
| M3 | Upgrades v1 | Card pick screen, 15 upgrades across categories, stacking, 2 synergies, run state |
| M4 | Difficulty + meta | 4 difficulty profiles, hangar, currency, save/load, settings menu |
| M5 | Sector 1 complete | 10 stages incl. boss (per design/intro-levels.md), 4 new enemies, tractor beam capture/dual fighter, medals |
| M6 | Art + audio pass | Chosen art style applied, SFX, adaptive music, juice |
| M7 | Content scale | Sectors 2 to 4, 40+ upgrades, more bosses, balance pass |
| M8 | Release polish | Touch controls, performance on low-end browsers, loading screen, itch.io/Pages release |

Art style decision is needed before M6; placeholders carry M0 to M5.

## 9. Session workflow and handoff

Sessions are short and stateless, so the project must be resumable from files alone.

### 9.1 Rules
- **One milestone task per session.** Pick the next unchecked item in `docs/roadmap.md`; finish it to a working, committed state rather than half-finishing two.
- **Always leave the game runnable.** Never end a session on a broken build; if a task can't finish, put it behind a flag or on a branch.
- **Decisions are written down** in `docs/decisions.md` with date and reason, so no session re-argues them.
- **Content changes need no code knowledge:** `docs/content-guide.md` explains how to add each data type.

### 9.2 Session start checklist
1. Read `handoff-for-next-session.md` (project root).
2. Read `docs/roadmap.md` for current milestone and next task.
3. Skim `docs/decisions.md` for recent entries.
4. Pull latest `main`, run tests, open the web build to confirm it still works.
5. Summarize where things stand before starting work.

### 9.3 Session end checklist
1. Tests pass; web build exports.
2. Commit with a clear message; push.
3. Tick off roadmap items.
4. Add any decisions to `docs/decisions.md`.
5. Rewrite `handoff-for-next-session.md` (template below), replacing, not appending, so it stays short.

### 9.4 Handoff template
```markdown
# Handoff for next session
Updated: YYYY-MM-DD · Milestone: Mx · Last commit: <hash> on <branch>

## Where we left off
2 to 4 sentences: what was done this session and current state of the build.

## Next task
The single next roadmap item, with any notes needed to start it.

## Open questions for Eric
- ...

## Known issues / gotchas
- ...

## Recent decisions
- YYYY-MM-DD: ... (full log in docs/decisions.md)
```

### 9.5 Design-aware handoff notes
Because the game is data-driven, a handoff should also record:
- **Balance state:** which tuning numbers changed and why (link `docs/balance.md`).
- **Content counts:** enemies / upgrades / stages built vs planned, so the next session knows whether to build systems or content.
- **Playtest feel notes:** what felt bad (e.g. "dives too predictable in stage 3") since feel is hard to recover from code.

## 10. Open decisions
1. Resolved 2026-10-02: combo-mode mapping confirmed (`docs/combo-styles.md`).
2. Resolved 2026-10-02: portrait orientation; repo `eagit2/gal`; two runtime-switched styles.
