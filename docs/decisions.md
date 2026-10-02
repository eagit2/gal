# Decision log

Newest first. One line per decision with the reason.

- 2026-10-02: Multiple combo types, each with its own trigger and its own art style (Eric). The proposed mapping is in docs/combo-styles.md and awaits confirmation.
- 2026-10-02: Two art styles switched at runtime: "Dusk Armada" (concept P2, 16-bit pixel over dithered sunset) base for most of the game, "Outrun Grid" (concept N1, synthwave wireframe) under certain level conditions. StyleDirector autoload + per-style Visual scenes; triggers are data. (Eric)
- 2026-10-02: Portrait orientation locked (540x960 internal). (Eric)
- 2026-10-02: Minimal in-repo test runner (`tests/run_tests.gd`) instead of gdUnit4. No addon dependency; enough for logic tests. Revisit if we need mocks or scene tests.
- 2026-10-02: Godot 4.5-stable pinned in CI.
- 2026-10-02: 540x960 portrait internal resolution as a placeholder until art style is chosen.
- 2026-10-02: Architecture accepted (docs/architecture.md); GitHub repo + Pages for builds.
- 2026-10-02: Browser target, Godot with web export.
