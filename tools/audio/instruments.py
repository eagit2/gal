"""Instrument voices for gen_music.py. Each takes (note, seconds held) and returns a mono array."""
import numpy as np

from synth import (SR, rng, bandpass, bitcrush, decay, env, highpass, hz, lowpass, osc, sweep,
                   sweep_lowpass, transpose)

QUALITIES = {
    "": [0, 4, 7, 12], "m": [0, 3, 7, 12], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
    "maj7": [0, 4, 7, 11], "sus2": [0, 2, 7, 12], "sus4": [0, 5, 7, 12], "dim": [0, 3, 6, 12],
    "m9": [0, 3, 10, 14], "add9": [0, 4, 7, 14],
}


def chord_notes(name: str, octave: int, count: int = 3) -> list:
    root = name[:2] if len(name) > 1 and name[1] in "#b" else name[:1]
    return [transpose(f"{root}{octave}", s) for s in QUALITIES[name[len(root):]][:count]]


def n(seconds: float) -> int:
    return int(seconds * SR)


def vibrato(f: float, m: int, depth: float = 0.006, rate: float = 5.5, delay: float = 0.15) -> np.ndarray:
    t = np.arange(m) / SR
    return f * (1 + depth * np.sin(2 * np.pi * rate * t) * np.clip((t - delay) / 0.2, 0, 1))


# --- melodic -----------------------------------------------------------------------------

def pulse_lead(note: str, held: float, duty: float = 0.25) -> np.ndarray:
    m = n(held + 0.08)
    x = osc("square", vibrato(hz(note), m), m, duty) * env(m, 0.004, 0.12, 0.65, 0.06, held)
    return lowpass(x, 5500) * 0.5


def pulse_half(note: str, held: float) -> np.ndarray:
    return pulse_lead(note, held, 0.5)


def pulse_thin(note: str, held: float) -> np.ndarray:
    return pulse_lead(note, held, 0.125)


def saw_lead(note: str, held: float) -> np.ndarray:
    m = n(held + 0.15)
    f = vibrato(hz(note), m, 0.008)
    x = (osc("saw", f * 0.996, m) + osc("saw", f * 1.004, m)) / 2
    x = sweep_lowpass(x, 5000, 1800) * env(m, 0.01, 0.2, 0.7, 0.12, held)
    return x * 0.45


def tri_lead(note: str, held: float) -> np.ndarray:
    m = n(held + 0.1)
    return osc("tri", vibrato(hz(note), m), m) * env(m, 0.01, 0.2, 0.8, 0.08, held) * 0.6


def pluck(note: str, held: float) -> np.ndarray:
    m = n(min(held, 0.25) + 0.25)
    x = osc("saw", hz(note), m) * 0.6 + osc("square", hz(note) * 1.003, m, 0.3) * 0.4
    return sweep_lowpass(x, 6000, 400) * decay(m, 0.35) * 0.4


def chip_arp(note: str, held: float) -> np.ndarray:
    m = n(held + 0.02)
    return osc("square", hz(note), m, 0.25) * env(m, 0.002, 0.05, 0.5, 0.02, held) * 0.3


def bell(note: str, held: float) -> np.ndarray:
    m = n(held + 0.6)
    f = hz(note)
    mod = osc("sine", f * 3.5, m) * 1.8 * decay(m, 0.4)
    t = np.arange(m) / SR
    x = np.sin(2 * np.pi * f * t + mod) * decay(m, 0.9)
    return x * 0.35


def glass(note: str, held: float) -> np.ndarray:
    m = n(held + 0.3)
    f = hz(note)
    x = osc("sine", f, m) + 0.3 * osc("sine", f * 2.01, m) + 0.15 * osc("sine", f * 4.02, m)
    return x * env(m, 0.003, 0.15, 0.35, 0.25, held) * 0.3


def gb_wave(note: str, held: float) -> np.ndarray:
    m = n(held + 0.01)
    return osc("wave4", hz(note), m) * env(m, 0.001, 0.05, 0.9, 0.01, held) * 0.55


# --- pads and bass -----------------------------------------------------------------------

def saw_pad(note: str, held: float) -> np.ndarray:
    m = n(held + 0.5)
    f = hz(note)
    x = sum(osc("saw", f * (1 + d), m) for d in (-0.007, 0.0, 0.006)) / 3
    return lowpass(x, 1800) * env(m, 0.35, 0.5, 0.8, 0.5, held) * 0.3


def warm_pad(note: str, held: float) -> np.ndarray:
    m = n(held + 0.8)
    f = hz(note)
    x = sum(osc("tri", f * (1 + d), m) for d in (-0.004, 0.004)) / 2 + 0.25 * osc("saw", f, m)
    return lowpass(x, 1300) * env(m, 0.8, 0.8, 0.85, 0.8, held) * 0.35


def gated_pad(note: str, held: float) -> np.ndarray:
    m = n(held + 0.05)
    f = hz(note)
    x = sum(osc("saw", f * (1 + d), m) for d in (-0.01, -0.003, 0.004, 0.011)) / 4
    return lowpass(x, 2600) * env(m, 0.01, 0.3, 0.9, 0.04, held) * 0.3


def saw_bass(note: str, held: float) -> np.ndarray:
    m = n(held + 0.03)
    f = hz(note)
    x = osc("saw", f, m) * 0.7 + osc("sine", f / 2, m) * 0.5
    return sweep_lowpass(x, 2400, 500) * env(m, 0.003, 0.1, 0.7, 0.03, held) * 0.6


def square_bass(note: str, held: float) -> np.ndarray:
    m = n(held + 0.02)
    x = osc("square", hz(note), m, 0.5) * env(m, 0.002, 0.08, 0.7, 0.02, held)
    return lowpass(x, 1400) * 0.5


def tri_bass(note: str, held: float) -> np.ndarray:
    m = n(held + 0.02)
    return osc("tri", hz(note), m) * env(m, 0.002, 0.1, 0.85, 0.02, held) * 0.8


def sub_bass(note: str, held: float) -> np.ndarray:
    m = n(held + 0.05)
    x = osc("sine", hz(note), m) + 0.2 * osc("tri", hz(note) * 2, m)
    return x * env(m, 0.005, 0.2, 0.8, 0.05, held) * 0.8


def grit_bass(note: str, held: float) -> np.ndarray:
    m = n(held + 0.03)
    f = hz(note)
    x = osc("square", f, m, 0.3) + osc("saw", f * 1.01, m)
    x = np.tanh(lowpass(x, 900) * 3) * env(m, 0.002, 0.1, 0.8, 0.03, held)
    return x * 0.4


def supersaw(note: str, held: float) -> np.ndarray:
    """Seven detuned saws with random phases: the trance chord sound."""
    m = n(held + 0.12)
    f = hz(note)
    t = np.arange(m) / SR
    x = sum(2.0 * ((f * (1 + d) * t + rng.random()) % 1.0) - 1.0
            for d in (-0.021, -0.013, -0.006, 0.0, 0.006, 0.013, 0.021)) / 7
    return lowpass(highpass(x, 120), 5200) * env(m, 0.005, 0.25, 0.85, 0.1, held) * 0.4


def saw_stab(note: str, held: float) -> np.ndarray:
    x = supersaw(note, max(held, 0.3))
    return x * decay(len(x), 0.35) * 1.3


def roll_bass(note: str, held: float) -> np.ndarray:
    """Short, punchy offbeat bass for rolling trance lines."""
    m = n(held + 0.01)
    f = hz(note)
    x = osc("saw", f, m) * 0.7 + osc("square", f / 2, m, 0.5) * 0.5
    return sweep_lowpass(x, 1800, 350) * env(m, 0.002, 0.06, 0.6, 0.01, held) * 0.75


def reese(note: str, held: float) -> np.ndarray:
    m = n(held + 0.05)
    f = hz(note)
    x = osc("saw", f * 0.993, m) + osc("saw", f * 1.007, m)
    x = np.tanh(lowpass(x, 650) * 2.5) * 0.5 + osc("sine", f / 2, m) * 0.6
    return x * env(m, 0.01, 0.2, 0.9, 0.05, held) * 0.6


def chip_lead(note: str, held: float) -> np.ndarray:
    """Square lead with a quick pitch blip at the start and fast vibrato, 16-bit RPG style."""
    m = n(held + 0.06)
    f = hz(note)
    t = np.arange(m) / SR
    blip = 1 + 0.03 * np.exp(-t / 0.012)
    vib = 1 + 0.01 * np.sin(2 * np.pi * 6.5 * t) * np.clip((t - 0.18) / 0.15, 0, 1)
    x = osc("square", f * blip * vib, m, 0.5) * 0.6 + osc("square", f * 1.004 * vib, m, 0.25) * 0.4
    return lowpass(x, 6500) * env(m, 0.003, 0.15, 0.7, 0.05, held) * 0.42


def brass(note: str, held: float) -> np.ndarray:
    """Synth brass for boss stabs: saw swell through an opening filter."""
    m = n(held + 0.1)
    f = hz(note)
    x = (osc("saw", f * 0.997, m) + osc("saw", f * 1.003, m)) / 2
    return sweep_lowpass(x, 900, 4200) * env(m, 0.03, 0.2, 0.8, 0.08, held) * 0.45


# --- drums -------------------------------------------------------------------------------

def kick(_note: str, _held: float) -> np.ndarray:
    m = n(0.32)
    body = osc("sine", sweep(150, 42, m, 0.35), m) * decay(m, 0.3)
    click = highpass(osc("noise", 0, m), 2000) * decay(m, 0.008) * 0.3
    return np.tanh((body + click) * 1.6) * 0.9


def trance_kick(_note: str, _held: float) -> np.ndarray:
    m = n(0.4)
    body = osc("sine", sweep(180, 46, m, 0.28), m) * decay(m, 0.38)
    click = highpass(osc("noise", 0, m), 2500) * decay(m, 0.006) * 0.5
    return np.tanh((body + click) * 2.2) * 0.95


def chip_kick(_note: str, _held: float) -> np.ndarray:
    m = n(0.12)
    return osc("square", sweep(220, 45, m, 0.5), m) * decay(m, 0.12) * 0.6


def snare(_note: str, _held: float) -> np.ndarray:
    m = n(0.22)
    tone_ = osc("tri", sweep(240, 170, m), m) * decay(m, 0.08)
    noise = bandpass(osc("noise", 0, m), 900, 8000) * decay(m, 0.18)
    return (tone_ * 0.5 + noise * 0.9) * 0.7


def big_snare(_note: str, _held: float) -> np.ndarray:
    m = n(0.5)
    noise = bandpass(osc("noise", 0, m), 600, 7000) * decay(m, 0.45)
    tone_ = osc("tri", sweep(220, 160, m), m) * decay(m, 0.12)
    return (noise + tone_ * 0.5) * 0.7


def clap(_note: str, _held: float) -> np.ndarray:
    m = n(0.25)
    burst = np.zeros(m)
    for k in (0, 0.01, 0.02):
        s = n(k)
        burst[s:] += decay(m - s, 0.03)
    burst += decay(m, 0.2) * 0.5
    return bandpass(osc("noise", 0, m), 1000, 5000) * burst * 0.6


def hat(_note: str, _held: float) -> np.ndarray:
    m = n(0.05)
    return highpass(osc("noise", 0, m), 7000) * decay(m, 0.04) * 0.35


def open_hat(_note: str, _held: float) -> np.ndarray:
    m = n(0.25)
    return highpass(osc("noise", 0, m), 6500) * decay(m, 0.22) * 0.3


def chip_noise(_note: str, _held: float) -> np.ndarray:
    m = n(0.07)
    return bitcrush(highpass(osc("noise", 0, m), 3000), 4, 6) * decay(m, 0.06) * 0.35


def chip_snare(_note: str, _held: float) -> np.ndarray:
    m = n(0.14)
    return bitcrush(osc("noise", 0, m), 4, 4) * decay(m, 0.12) * 0.5


def tom(_note: str, _held: float) -> np.ndarray:
    m = n(0.3)
    return osc("sine", sweep(160, 70, m, 0.5), m) * decay(m, 0.28) * 0.7


def crash(_note: str, _held: float) -> np.ndarray:
    m = n(1.6)
    return highpass(osc("noise", 0, m), 4000) * decay(m, 1.5) * 0.25


def riser(_note: str, held: float) -> np.ndarray:
    m = n(held)
    x = highpass(osc("noise", 0, m), 2000) * np.linspace(0, 1, m) ** 2
    return sweep_lowpass(x, 800, 12000) * 0.35


INSTRUMENTS = {name: fn for name, fn in globals().items()
               if callable(fn) and fn.__module__ == __name__ and name not in ("chord_notes", "n", "vibrato")}
