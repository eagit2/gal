# Modern Galaga

A modern take on Galaga for the browser: deep upgrade system, selectable difficulty, varied sectors and bosses. Built with Godot 4.5 (GDScript, Compatibility renderer). Portrait; a "dusk armata" base art style that switches to neon outrun under certain level conditions.

## Run
Open the folder in Godot 4.5 and press F5. Main scene: `scenes/main/boot.tscn`.

## Test
```
godot --headless -s res://tests/run_tests.gd
```
Tests live in `tests/unit/test_*.gd`, extend `TestCase`, and use `expect_*` helpers.

## Web build
CI exports the `Web` preset (single-threaded, no special headers needed) and publishes it to GitHub Pages on every push to `main`. Locally: install the 4.5 export templates, then
```
godot --headless --export-release "Web" build/web/index.html
```

## Docs
- `docs/architecture.md` design and code architecture
- `docs/roadmap.md` milestones and status
- `docs/decisions.md` decision log
- `docs/content-guide.md` how to add content
