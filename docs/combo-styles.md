> 2026-10-03: Eric asked that combos stop changing the screen. Modes keep their meters and buffs; `ComboDef.style` is empty, so the art style and music stay put. The style mapping below is kept for reference.

# Combo modes and art styles

Status: decided, 2026-10-02 (Eric confirmed the mapping. Original ask: "combos need to be triggered in a certain way... multiple types, each leading to a different art style").
Art concepts: https://claude.ai/artifact/4E2e82z6Ss4LiyFTZt6hj1

## Idea
The game runs in the **Dusk Armada** style (P2). Playing in a specific way fills one of four **combo meters**. A full meter triggers a **combo mode** for a few seconds. Each mode has its own art style, music stems, and a gameplay buff that rewards the same play that triggered it. The style change tells the player at a glance what they pulled off.

## The four modes

| Mode | Trigger (what fills the meter) | Art style | Buff while active | Feel |
|---|---|---|---|---|
| **Overkill** (id overdrive) | Every 30 kills (no streak window, no decay). | N1 Outrun Grid | Fire rate x1.5, ship speed x1.2 | Aggression |
| **Chain** (id lock_on) | 30 hits in a row with no missed shot; a miss resets it. | N3 Cold Hologram | Every hit arcs big lightning to 5 nearby enemies | Precision |
| **Chain Reaction** | Multi-kills: 3 or more kills from one shot or explosion, or killing a diver mid-dive. The meter fills at 6 events. | N2 Particle Storm | Kills explode and damage neighbors | Chaos |
| **Graze** | Near misses: enemy bullets passing within a small radius of the hitbox without hitting. The meter fills at 30. | P3 Pocket Four | Time slows to 0.6x, and grazes give score | Risk |

Bonus: rescuing a captured ship (tractor beam) triggers **Arcade '81** in P1 Arcade Classic+ style for 8s. It uses classic sounds, and its buff is double score. It's a tribute moment.

## Rules
- **Upgrade bubbles (2026-10-03, Eric):** a full meter does not start the mode. It drops an upgrade bubble that falls at twice scrap pace; catching it starts the mode (chaining if one is running). A missed bubble empties the meter. Triggered extras (Cryo Pulse, the no-hit companion drone) drop bubbles at scrap pace.
- **Duration:** 8 seconds per mode. A HUD ring shows the remaining time.
- **One at a time.** While a mode is active, the other meters keep filling but can't trigger.
- **Style Chain:** if another meter is full when the current mode ends, it triggers right away and gives a +1 chain multiplier on score (x2, x3...). That's the high-skill goal.
- **Decay:** each meter drains slowly when its action isn't happening (about 10% per second after 2s idle), so a meter tracks your current play rather than everything you've done in the stage.
- **Stage overrides:** some stages force a style for the whole stage (`StageDef.style`), for example an outrun-themed sector stage. Combo modes still trigger on top and give their buff, but don't change the art.
- **Bosses:** a boss's final phase can force a mode (`BossDef` phase field), for example Overdrive for a last stand.

## Ties to other systems
- **Upgrades:** some upgrade cards target meters, like *Graze Plating* (+50% graze gain), *Hair Trigger* (Overdrive window 1.2s → 1.6s), and *Fuse Shells* (Chain events count double). There are synergies with weapon types, such as Piercing + Chain Reaction. This makes builds lean toward a favorite mode.
- **Difficulty:** `DifficultyDef` scales meter thresholds (Cadet 0.75x, Nightmare 1.25x) and mode duration.
- **Meta:** the hangar unlocks modes. The run starts with Overdrive only, and the others unlock through play, which gives early sessions a goal.
- **Audio:** each style has its own music stem set. Mode start and end use a stinger and a crossfade on the beat.

## Art cost
- P2 Dusk Armada (base) gets full sprite work.
- N1, N2 and N3 are mostly code and shaders: vector ships via `_draw()`, background shaders, and glow. They're cheap.
- P3 Pocket Four is a full-screen 4-shade palette shader over the P2 sprites. It's nearly free.
- P1 Arcade Classic+ is a palette swap of the P2 sprites without outlines, with a starfield background. It's cheap.

Each entity has a `Visual` node with children `base` (P2 sprite) and `vector` (N-style polylines, recolored per neon style). `StyleDirector` tells visuals which child to show and which palette or shader to apply. Five styles from about 1.3 art sets.

## Implementation
- `ComboTracker` (system): listens to `EventBus` (`enemy_killed`, `shot_fired`, `shot_missed`, `bullet_grazed`, `ship_rescued`), owns the meters, and emits `combo_started(mode)` and `combo_ended(mode, chain)`.
- `ComboDef` resource per mode: id, style id, threshold, window, decay, duration, buff effects (same effect format as `UpgradeDef`).
- `StyleDirector` (autoload): applies the style for `combo_started`, a stage override, or a boss phase, by priority. It runs the transition: a 0.3s flash or wipe, a palette tween, and a music crossfade.
- Thresholds and durations live in `data/combos/*.tres` and get tuned in playtests.
