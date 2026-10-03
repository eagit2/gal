# Decision log

Newest first. One line per decision with the reason.

- 2026-10-03: Pacing must feel frantic (Eric's M2 playtest). Enemy attacks are steered live by per-type brains (`EnemyBrain` resources in `data/brains/`) instead of fixed dive curves; entries still fly in on data paths. Squads attack from 2s into a stage, formation fires, and reinforcement squads refill the formation.
- 2026-10-03: The player shield is an always-on bubble that absorbs one hit (shot or ram, the rammer dies) and recharges (Eric picked "Auto bubble"). Recharge time is a DifficultyDef value.
- 2026-10-03: Hit feedback lives in the visual (`DamageFx`), driven by the entity's `Health.damaged` signal. Gameplay scripts don't tint or flash sprites, so movement code can change freely. Ships with more than 1 HP get damaged frames and smoke at half health or below. (Eric asked for damage animations.)
- 2026-10-03: Shots are glowing energy (an additive glow under a pixel core, no outline): the player fires cyan tracers with a muzzle flash, and enemies fire plasma orbs in the reserved red. (Eric asked for realistic-looking bullets.)
- 2026-10-03: The sky is a smooth, undithered gradient in natural dusk colors (night blue to warm gold), not pixel bands (Eric). Sprites and clouds stay pixel art.
- 2026-10-02: Dusk Armada pixel art is generated from ASCII pixel maps by `tools/art/gen_dusk_armada.py` (1x for a 270x480 grid, shown at 2x with nearest filtering). Edits are text diffs and need no image editor.
- 2026-10-02: Enemy sprites face down (head toward the player), so dives lead with the head under the current rotation rule.
- 2026-10-02: The sky ends in a dark cloud sea at 80% height. Over the bright sunset bands, orange enemies and the reserved bullet red were hard to read in the player zone.
- 2026-10-02: Sprite visuals keep a hidden `Silhouette` of polygons inside their `dusk_armada` child, so vector styles still get the generated wireframe.
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
