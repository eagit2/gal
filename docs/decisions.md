# Decision log

Newest first. One line per decision with the reason.

- 2026-10-03: Pacing must feel frantic (Eric's M2 playtest). Enemy attacks are steered live by per-type brains (`EnemyBrain` resources in `data/brains/`) instead of fixed dive curves; entries still fly in on data paths. Squads attack from 2s into a stage, formation fires, and reinforcement squads refill the formation.
- 2026-10-03: The player shield is an always-on bubble that absorbs one hit (shot or ram, the rammer dies) and recharges (Eric picked "Auto bubble"). Recharge time is a DifficultyDef value.
- 2026-10-02: Sector 1 has 10 stages (9 + boss, challenges at 3 and 7). Later sectors default to 5 + boss. The boss has unique attacks and mechanics. (Eric, Level design thread.) Enemy ids now follow that design: butterfly → moth, boss → warden.
- 2026-10-02: Upgrades also drop randomly from kills, by probability (DropTable + pity bonus), adding to the 1-of-3 card pick. Stage medals earn the meta currency. (Eric, Level design thread; see design/intro-levels.md 2.1.)
- 2026-10-02: Ramming destroys the enemy too (Eric). Score is awarded as a normal kill.
- 2026-10-02: Glow for the outrun grid is computed in the shader rather than with WorldEnvironment glow: it's guaranteed on the web Compatibility renderer and costs one full-screen pass. Revisit for sprites in M6.
- 2026-10-02: Vector styles get an auto-generated wireframe from each visual's base polygons (StyledVisual), so a new entity needs one drawing, not one per style.
- 2026-10-02: Style priority: debug (F2) > combo (M3) > stage style > base.
- 2026-10-02: Only diving enemies shoot (Galaga rule); formation enemies hold fire.
- 2026-10-02: Player can move over the full screen height, not just the bottom band (Eric playtest).
- 2026-10-02: Input actions registered in code (`autoload/controls.gd`) rather than project.godot, so bindings are readable and diffable.
- 2026-10-02: Physics layers: 1 player_hurtbox, 2 enemy_hurtbox, 3 player_shots, 4 enemy_shots. Hitboxes monitor; Hurtboxes are monitorable only.
- 2026-10-02: Game root runs while paused (reads pause key); `Entities` is pausable.
- 2026-10-02: Enemy bullets use the reserved pink-red; nothing else on screen uses it.
- 2026-10-02: Multiple combo types, each with its own trigger and its own art style (Eric). Mapping in docs/combo-styles.md, confirmed by Eric.
- 2026-10-02: Two art styles switched at runtime: "Dusk Armada" (concept P2, 16-bit pixel over dithered sunset) base for most of the game, "Outrun Grid" (concept N1, synthwave wireframe) under certain level conditions. StyleDirector autoload + per-style Visual scenes; triggers are data. (Eric)
- 2026-10-02: Portrait orientation locked (540x960 internal). (Eric)
- 2026-10-02: Minimal in-repo test runner (`tests/run_tests.gd`) instead of gdUnit4. No addon dependency; enough for logic tests. Revisit if we need mocks or scene tests.
- 2026-10-02: Godot 4.5-stable pinned in CI.
- 2026-10-02: 540x960 portrait internal resolution as a placeholder until art style is chosen.
- 2026-10-02: Architecture accepted (docs/architecture.md); GitHub repo + Pages for builds.
- 2026-10-02: Browser target, Godot with web export.
