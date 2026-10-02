# Rules for AI sessions

1. At session start: read `handoff-for-next-session.md` (project root, outside this repo), then `docs/roadmap.md` and recent `docs/decisions.md`. Summarize where things stand before working.
2. Work on one roadmap task per session. Leave the game runnable; unfinished work goes on a branch.
3. Content is data: add `.tres` files under `data/`, not new code paths. No `if difficulty == ...` branches; use `DifficultyDef` values.
4. Gameplay scripts never reference sprites directly; visuals live in a `Visual` child scene under `assets/art/<style>/`.
5. Systems talk through `EventBus` signals. Static typing everywhere. Keep scripts under ~300 lines.
6. Before ending: run tests (`godot --headless -s res://tests/run_tests.gd`), commit, tick `docs/roadmap.md`, log decisions, rewrite the handoff file (replace, don't append).
