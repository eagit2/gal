"""Tiny offline synth used by gen_sfx.py and gen_music.py. Needs numpy and scipy.

Everything is float arrays at SR. Music is rendered twice in a row and the second copy is kept,
so note tails and delay/reverb tails wrap into the loop start and the loop is seamless.
"""
import subprocess
import wave
from pathlib import Path

import numpy as np
from scipy import signal

SR = 44100
NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
rng = np.random.default_rng(1981)


def hz(note: str) -> float:
    """'A4', 'C#3', 'Bb2' -> frequency."""
    name, octave = note[:-1], int(note[-1])
    semis = NOTE_INDEX[name[0]] + name[1:].count("#") - name[1:].count("b")
    return 440.0 * 2 ** ((semis + 12 * (octave + 1) - 69) / 12)


def transpose(note: str, semis: int) -> str:
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    name, octave = note[:-1], int(note[-1])
    midi = NOTE_INDEX[name[0]] + name[1:].count("#") - name[1:].count("b") + 12 * (octave + 1) + semis
    return f"{names[midi % 12]}{midi // 12 - 1}"


# --- oscillators -------------------------------------------------------------------------

def phase(freq, n: int) -> np.ndarray:
    """Phase in cycles; freq may be a number or an array (slides, vibrato)."""
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    return np.cumsum(f) / SR


def osc(kind: str, freq, n: int, duty: float = 0.5) -> np.ndarray:
    p = phase(freq, n) % 1.0
    if kind == "sine":
        return np.sin(2 * np.pi * p)
    if kind == "square":
        return np.where(p < duty, 1.0, -1.0)
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "tri":
        return 4.0 * np.abs(p - 0.5) - 1.0
    if kind == "noise":
        return rng.uniform(-1, 1, n)
    if kind == "wave4":  # 4-bit stepped triangle, Game Boy wave channel flavour
        return np.round((4.0 * np.abs(p - 0.5) - 1.0) * 7.5) / 7.5
    raise ValueError(kind)


def env(n: int, a: float = 0.005, d: float = 0.1, s: float = 0.7, r: float = 0.05,
        gate: float | None = None) -> np.ndarray:
    """ADSR over n samples. gate (seconds) is when release starts; default n - r."""
    t = np.arange(n) / SR
    gate = (n / SR - r) if gate is None else gate
    out = np.where(t < a, t / max(a, 1e-6), s + (1 - s) * np.exp(-(t - a) / max(d, 1e-6) * 3))
    rel = np.clip(1 - (t - gate) / max(r, 1e-6), 0, 1)
    return out * np.where(t > gate, rel, 1.0)


def decay(n: int, time: float) -> np.ndarray:
    return np.exp(-np.arange(n) / SR / time * 5)


def sweep(f0: float, f1: float, n: int, curve: float = 1.0) -> np.ndarray:
    x = np.linspace(0, 1, n) ** curve
    return f0 * (f1 / f0) ** x


# --- filters and effects -----------------------------------------------------------------

def lowpass(x: np.ndarray, cutoff: float, order: int = 2) -> np.ndarray:
    b, a = signal.butter(order, min(cutoff, SR * 0.45) / (SR / 2), "low")
    return signal.lfilter(b, a, x, axis=0)


def highpass(x: np.ndarray, cutoff: float, order: int = 2) -> np.ndarray:
    b, a = signal.butter(order, cutoff / (SR / 2), "high")
    return signal.lfilter(b, a, x, axis=0)


def bandpass(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    b, a = signal.butter(2, [lo / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x, axis=0)


def sweep_lowpass(x: np.ndarray, f0: float, f1: float, block: int = 256) -> np.ndarray:
    """Time-varying one-pole-ish lowpass (block-wise state carried over)."""
    out = np.zeros_like(x)
    cut = sweep(f0, f1, len(x) // block + 1)
    zi = None
    for i, c in enumerate(cut):
        seg = x[i * block:(i + 1) * block]
        if len(seg) == 0:
            break
        b, a = signal.butter(2, min(c, SR * 0.45) / (SR / 2), "low")
        if zi is None:
            zi = signal.lfilter_zi(b, a) * 0
        out[i * block:i * block + len(seg)], zi = signal.lfilter(b, a, seg, zi=zi)
    return out


def comb(x: np.ndarray, delay_s: float, feedback: float) -> np.ndarray:
    """y[n] = x[n] + feedback * y[n - d], computed a delay-length block at a time."""
    d = max(1, int(delay_s * SR))
    y = np.array(x, dtype=float)
    for start in range(d, len(y), d):
        end = min(start + d, len(y))
        y[start:end] += feedback * y[start - d:end - d]
    return y


def allpass(x: np.ndarray, delay_s: float, g: float) -> np.ndarray:
    """y[n] = -g x[n] + x[n - d] + g y[n - d]."""
    d = max(1, int(delay_s * SR))
    y = -g * np.array(x, dtype=float)
    y[d:] += x[:-d]
    for start in range(d, len(y), d):
        end = min(start + d, len(y))
        y[start:end] += g * y[start - d:end - d]
    return y


def echo(x: np.ndarray, delay_s: float, feedback: float, mix: float, damp: float = 3000) -> np.ndarray:
    """Feedback delay; wet path is darkened. Mono in, mono out."""
    d = int(delay_s * SR)
    wet = np.zeros_like(x)
    wet[d:] = x[:-d]
    wet = comb(lowpass(wet, damp, 1), delay_s, feedback)
    return x + mix * wet


def reverb(x: np.ndarray, size: float = 1.0, mix: float = 0.2) -> np.ndarray:
    """Small Schroeder reverb (4 combs + 2 allpasses)."""
    wet = sum(comb(x, t * size, 0.78) for t in (0.0297, 0.0371, 0.0411, 0.0437)) / 4
    for t, g in ((0.005, 0.7), (0.0017, 0.7)):
        wet = allpass(wet, t, g)
    return x + mix * lowpass(wet, 5000, 1)


def bitcrush(x: np.ndarray, bits: int = 6, hold: int = 2) -> np.ndarray:
    q = 2 ** (bits - 1)
    y = np.round(x * q) / q
    return np.repeat(y[::hold], hold)[:len(x)]


def soft_clip(x: np.ndarray, drive: float = 1.0) -> np.ndarray:
    return np.tanh(x * drive) / np.tanh(drive)


def normalize(x: np.ndarray, peak: float = 0.9) -> np.ndarray:
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


def fade_out(x: np.ndarray, time: float = 0.01) -> np.ndarray:
    n = min(len(x), int(time * SR))
    x = x.copy()
    x[-n:] *= np.linspace(1, 0, n)[:, None] if x.ndim == 2 else np.linspace(1, 0, n)
    return x


# --- output ------------------------------------------------------------------------------

def write_wav(path: Path, x: np.ndarray, rate: int = SR) -> None:
    """Mono or stereo (n, 2) float -> 16-bit PCM."""
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1 if x.ndim == 1 else 2)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data.tobytes())


def write_ogg(path: Path, x: np.ndarray, quality: int = 4) -> None:
    """Encodes via ffmpeg (libvorbis)."""
    tmp = path.with_suffix(".tmp.wav")
    write_wav(tmp, x)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis",
                    "-q:a", str(quality), str(path)], check=True)
    tmp.unlink()
