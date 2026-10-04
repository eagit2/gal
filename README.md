# Overkill Armada

A modern take on Galaga for the browser: deep upgrade system, selectable difficulty, varied sectors and bosses. Built with Godot 4.5 (GDScript, Compatibility renderer). Portrait; a "Dusk Armada" 16-bit pixel base art style that switches to neon "Outrun Grid" under certain level conditions.

## Run
Open the folder in Godot 4.5 and press F5. Main scene: `scenes/main/boot.tscn`.

## Controls
Arrows/WASD move, Space/Z fire, Esc/P pause, F2 cycles art styles (debug). Gamepad: stick or D-pad, A fire, Start pause. Touch: drag to move (auto-fire).

## Test
```
godot --headless -s res://tests/run_tests.gd
godot --headless --fixed-fps 60 -s res://tests/smoke_game.gd -- --seconds=45      # simulated playthrough
godot --headless --fixed-fps 60 -s res://tests/smoke_game.gd -- --seconds=25 stage=challenge_1  # challenge stage
```
Tests live in `tests/unit/test_*.gd`, extend `TestCase`, and use `expect_*` helpers.

## Screenshots
`tools/screenshot.gd` renders frames to PNG (see its header; works in containers with `xvfb-run`).

## Art
Dusk Armada sprites are generated: edit the pixel maps in `tools/art/gen_dusk_armada.py`, then run `python3 tools/art/gen_dusk_armada.py` (needs Pillow) and reimport.

## Web build
CI exports the `Web` preset (single-threaded, no special headers needed) and publishes it to GitHub Pages on every push to `main`. Locally: install the 4.5 export templates, then
```
godot --headless --export-release "Web" build/web/index.html
```

## Docs
- `docs/architecture.md` design and code architecture
- `docs/roadmap.md` milestones and status
- `docs/decisions.md` decision log
- `docs/combo-styles.md` combo modes and art styles
- `docs/content-guide.md` how to add content
