#!/usr/bin/env python3
"""Generates every sound effect into assets/audio/sfx/*.wav. All sounds are original synthesis.

Run: python3 tools/audio/gen_sfx.py [sound ...]   (needs numpy, scipy)
Sound ids match data/audio/sound_bank.tres. Keep effects short; music lives in gen_music.py.
"""
import sys
from pathlib import Path

import numpy as np

from synth import (SR, bandpass, bitcrush, decay, echo, env, fade_out, highpass, hz, lowpass,
                   normalize, osc, reverb, soft_clip, sweep, write_wav)

OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"


def n(seconds: float) -> int:
    return int(seconds * SR)


def tone(kind: str, note_or_hz, seconds: float, duty: float = 0.5, **adsr) -> np.ndarray:
    f = hz(note_or_hz) if isinstance(note_or_hz, str) else note_or_hz
    return osc(kind, f, n(seconds), duty) * env(n(seconds), **adsr)


def mix(*parts: np.ndarray) -> np.ndarray:
    """Sums sounds of different lengths."""
    out = np.zeros(max(len(p) for p in parts))
    for p in parts:
        out[:len(p)] += p
    return out


def seq(parts: list, gap: float) -> np.ndarray:
    """Places sounds gap seconds apart (overlapping allowed)."""
    total = n(gap * (len(parts) - 1)) + max(len(p) for p in parts)
    out = np.zeros(total)
    for i, p in enumerate(parts):
        out[n(gap * i):n(gap * i) + len(p)] += p
    return out


def shot() -> np.ndarray:
    m = n(0.07)
    body = osc("square", sweep(1500, 520, m, 0.6), m, 0.25) * decay(m, 0.07)
    click = highpass(osc("noise", 0, m), 3000) * decay(m, 0.015)
    return lowpass(body * 0.6 + click * 0.3, 7000)


def shot_hit() -> np.ndarray:
    m = n(0.06)
    ping = osc("square", sweep(2400, 1700, m), m, 0.5) * decay(m, 0.04)
    return lowpass(ping * 0.5 + highpass(osc("noise", 0, m), 4000) * decay(m, 0.02) * 0.4, 9000)


def explosion(seconds: float, cutoff: float, thump: float, crush: int) -> np.ndarray:
    m = n(seconds)
    noise = osc("noise", 0, m)
    body = lowpass(noise, cutoff) * decay(m, seconds * 0.8)
    crackle = bandpass(noise, 1500, 6000) * decay(m, seconds * 0.25) * 0.35
    sub = osc("sine", sweep(thump, 35, m, 0.5), m) * decay(m, seconds * 0.5)
    mix = bitcrush(body * 1.4 + crackle + sub, crush, 3)
    return soft_clip(lowpass(mix, cutoff * 1.6), 1.6)


def player_hit() -> np.ndarray:
    m = n(1.3)
    boom = np.zeros(m)
    big = explosion(1.1, 1400, 140, 5)
    boom[:len(big)] += big
    fall = osc("square", sweep(880, 55, m, 0.7), m, 0.4) * decay(m, 1.3) * 0.35
    return reverb(soft_clip(boom + lowpass(fall, 3000), 1.4), 0.9, 0.25)


def shield_pop() -> np.ndarray:
    m = n(0.6)
    glass = sum(osc("sine", f, m) * decay(m, 0.25 + i * 0.04) for i, f in
                enumerate((2093, 2793, 3322, 4186, 5274)))
    shards = bandpass(osc("noise", 0, m), 3000, 9000) * decay(m, 0.22)
    thud = osc("sine", sweep(300, 80, m), m) * decay(m, 0.08)
    return reverb(glass * 0.3 + shards * 1.0 + thud * 0.7, 0.7, 0.3)


def shield_restore() -> np.ndarray:
    notes = ["E5", "G#5", "B5", "E6"]
    parts = [mix(tone("tri", x, 0.35, a=0.01, d=0.2, s=0.3, r=0.1) * 0.5,
                 tone("square", x, 0.2, 0.125, a=0.005, d=0.1, s=0.2, r=0.05) * 0.12) for x in notes]
    return reverb(echo(seq(parts, 0.07), 0.11, 0.3, 0.3), 0.8, 0.25)


def graze() -> np.ndarray:
    m = n(0.09)
    zip_ = osc("tri", sweep(3200, 5200, m), m) * decay(m, 0.06)
    hiss = highpass(osc("noise", 0, m), 6000) * decay(m, 0.04)
    return zip_ * 0.3 + hiss * 0.3


def pickup() -> np.ndarray:
    parts = [tone("square", x, 0.12, 0.25, a=0.002, d=0.05, s=0.5, r=0.04) for x in ("C6", "E6", "G6", "C7")]
    return echo(lowpass(seq(parts, 0.045), 8000) * 0.5, 0.09, 0.25, 0.3)


def chord(notes: list, seconds: float, kind: str = "saw", detune: float = 0.004) -> np.ndarray:
    m = n(seconds)
    out = np.zeros(m)
    for x in notes:
        for dt in (-detune, detune):
            out += osc(kind, hz(x) * (1 + dt), m)
    return out / (2 * len(notes))


def upgrade_pick() -> np.ndarray:
    pad = lowpass(chord(["A4", "C#5", "E5", "A5"], 0.9), 3500) * env(n(0.9), 0.01, 0.3, 0.4, 0.3)
    bell = seq([tone("sine", x, 0.6, a=0.002, d=0.25, s=0.0, r=0.1) for x in ("E6", "A6")], 0.08)
    return reverb(mix(pad * 0.8, bell * 0.4), 1.0, 0.3)


def combo_start() -> np.ndarray:
    m = n(1.1)
    rise = osc("saw", sweep(110, 880, m, 1.8), m) * env(m, 0.4, 0.2, 0.8, 0.4)
    rise = lowpass(rise, 4000) * 0.35 + highpass(osc("noise", 0, m), 5000) * np.linspace(0, 0.25, m)
    stab = lowpass(chord(["D4", "F#4", "A4", "D5"], 0.7), 5000) * env(n(0.7), 0.003, 0.25, 0.3, 0.2)
    out = np.zeros(n(0.55) + len(stab))
    out[:m] += rise
    out[n(0.55):] += stab * 0.9
    return reverb(soft_clip(out, 1.3), 1.1, 0.3)


def combo_end() -> np.ndarray:
    m = n(0.6)
    fall = osc("saw", sweep(880, 110, m, 0.7), m) * env(m, 0.005, 0.3, 0.3, 0.2)
    return reverb(lowpass(fall, 2500) * 0.45, 0.9, 0.3)


def synergy() -> np.ndarray:
    notes = ["G5", "B5", "D6", "F#6", "A6"]
    parts = [mix(tone("sine", x, 0.7, a=0.002, d=0.3, s=0.0, r=0.1) * 0.5,
                 tone("square", x, 0.08, 0.125) * 0.1) for x in notes]
    return reverb(echo(seq(parts, 0.05), 0.13, 0.35, 0.35), 1.1, 0.3)


def melody(notes: list, step: float, kind: str = "square", duty: float = 0.25, bass: list | None = None) -> np.ndarray:
    """notes: note name or '-' (hold previous) or '.' (rest), one per step."""
    events = []
    for i, x in enumerate(notes):
        if x not in ("-", "."):
            length = 1
            while i + length < len(notes) and notes[i + length] == "-":
                length += 1
            events.append((i, x, length))
    out = np.zeros(n(step * len(notes) + 0.6))
    for i, x, length in events:
        t = mix(tone(kind, x, step * length + 0.05, duty, a=0.004, d=0.08, s=0.6, r=0.05),
                tone("tri", x, step * length + 0.05, a=0.004, d=0.1, s=0.5, r=0.05) * 0.5)
        out[n(step * i):n(step * i) + len(t)] += t
    if bass:
        for i, x in enumerate(bass):
            if x not in ("-", "."):
                t = tone("tri", x, step * 2, a=0.004, d=0.2, s=0.6, r=0.04)
                out[n(step * i):n(step * i) + len(t)] += t * 0.8
    return reverb(echo(lowpass(out, 6000) * 0.4, step * 3, 0.25, 0.25), 1.0, 0.2)


def stage_start() -> np.ndarray:
    return melody(["D5", "A4", "D5", "F5", "E5", "-", "A5", "-", "-", "."], 0.11,
                  bass=["D3", ".", ".", ".", "A2", ".", "D3", ".", ".", "."])


def stage_clear() -> np.ndarray:
    return melody(["A4", "C5", "E5", "A5", "G5", "E5", "F5", "-", "G5", "-", "A5", "-", "-", "-"], 0.1,
                  bass=["A2", ".", ".", ".", "C3", ".", "F2", ".", "G2", ".", "A2", ".", ".", "."])


def game_over() -> np.ndarray:
    return melody(["E5", "-", "D5", "-", "C5", "-", "B4", "-", "A4", "-", "G#4", "-", "A4", "-", "-", "-", "-", "-"],
                  0.16, kind="square", duty=0.5,
                  bass=["A2", ".", ".", ".", "F2", ".", ".", ".", "D2", ".", "E2", ".", "A1", ".", ".", ".", ".", "."])


def elite_alert() -> np.ndarray:
    """Two short low blips: a warning that doesn't clash with the music's key."""
    blip = lambda: tone("square", 220, 0.07, 0.5, a=0.001, d=0.03, s=0.5, r=0.02) * 0.4
    return seq([blip(), blip()], 0.11)


def ui_move() -> np.ndarray:
    return tone("square", "E6", 0.035, 0.25, a=0.001, d=0.02, s=0.3, r=0.01) * 0.25


def ui_confirm() -> np.ndarray:
    return seq([tone("square", x, 0.08, 0.25, a=0.001, d=0.04, s=0.4, r=0.02) * 0.3 for x in ("A5", "E6")], 0.06)


def ui_back() -> np.ndarray:
    return seq([tone("square", x, 0.08, 0.25, a=0.001, d=0.04, s=0.4, r=0.02) * 0.3 for x in ("E6", "A5")], 0.06)


SOUNDS = {
    "shot": (shot, 0.5), "shot_hit": (shot_hit, 0.5),
    "explode_small": (lambda: explosion(0.45, 2200, 180, 6), 0.8),
    "explode_big": (lambda: explosion(0.9, 1600, 120, 5), 0.9),
    "player_hit": (player_hit, 0.95), "shield_pop": (shield_pop, 0.8),
    "shield_restore": (shield_restore, 0.6), "graze": (graze, 0.4), "pickup": (pickup, 0.7),
    "upgrade_pick": (upgrade_pick, 0.7), "combo_start": (combo_start, 0.85), "combo_end": (combo_end, 0.6),
    "synergy": (synergy, 0.7), "stage_start": (stage_start, 0.7), "stage_clear": (stage_clear, 0.7),
    "game_over": (game_over, 0.75), "ui_move": (ui_move, 0.4), "ui_confirm": (ui_confirm, 0.5),
    "ui_back": (ui_back, 0.5), "elite_alert": (elite_alert, 0.55),
}


def main() -> None:
    names = sys.argv[1:] or list(SOUNDS)
    for name in names:
        make, peak = SOUNDS[name]
        x = fade_out(normalize(np.asarray(make(), dtype=float), peak), 0.008)
        write_wav(OUT / f"{name}.wav", x)
        print(f"{name}.wav  {len(x) / SR:.2f}s")


if __name__ == "__main__":
    main()
