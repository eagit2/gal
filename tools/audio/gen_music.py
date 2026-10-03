#!/usr/bin/env python3
"""Generates the looping music tracks into assets/audio/music/*.ogg. All music is original.

Run: python3 tools/audio/gen_music.py [track ...]   (needs numpy, scipy, ffmpeg with libvorbis)

A track is a tempo, a chord progression and some lines. Melodies are written one token per
16th note: a note name starts a note, '-' holds it, '.' is a rest, '|' is ignored (bar marker).
Drum lines are one character per 16th: 'x' hit, 'o' soft hit, '.' nothing.
Each track renders twice and keeps the second pass, so tails wrap and the loop is seamless.
"""
import sys
from pathlib import Path

import numpy as np

from instruments import INSTRUMENTS, chord_notes
from synth import SR, hz, osc, env, bitcrush, echo, highpass, lowpass, normalize, reverb, soft_clip, write_ogg
from tracks import TRACKS

OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "music"


class Track:
    def __init__(self, bpm: float, bars: int, chords: list):
        self.step = 60.0 / bpm / 4
        self.bars = bars
        self.chords = chords  # one per bar, repeated to fill
        self.steps = bars * 16
        self.length = int(round(self.steps * self.step * SR))
        self.mix = np.zeros((2 * self.length + SR * 2, 2))
        self.kicks: list[int] = []

    def at(self, step: int) -> int:
        return int(round(step * self.step * SR))

    def chord(self, bar: int) -> str:
        return self.chords[bar % len(self.chords)]

    def _place(self, bus: np.ndarray, sound: np.ndarray, step: int) -> None:
        for offset in (0, self.length):
            start = self.at(step) + offset
            end = min(start + len(sound), len(bus))
            bus[start:end] += sound[:end - start]

    def _finish(self, bus: np.ndarray, gain: float, pan: float, fx: dict) -> None:
        if fx.get("lowpass"):
            bus = lowpass(bus, fx["lowpass"])
        if fx.get("gate"):
            bus = bus * self._gate(fx["gate"])
        if fx.get("pump"):
            bus = bus * self._pump(fx["pump"])
        if fx.get("crush"):
            bus = bitcrush(bus, *fx["crush"])
        if fx.get("drive"):
            bus = soft_clip(bus, fx["drive"])
        if fx.get("echo"):
            beats, fb, mix = fx["echo"]
            bus = echo(bus, beats * self.step * 4, fb, mix)
        if fx.get("reverb"):
            bus = reverb(bus, *fx["reverb"])
        left, right = np.sqrt((1 - pan) / 2), np.sqrt((1 + pan) / 2)
        width = fx.get("width", 0)
        if width:  # Haas-style widening for pads
            d = int(width * SR)
            delayed = np.concatenate([np.zeros(d), bus[:-d]])
            self.mix[:, 0] += bus * gain * left
            self.mix[:, 1] += delayed * gain * right
            return
        self.mix[:, 0] += bus * gain * left
        self.mix[:, 1] += bus * gain * right

    def _gate(self, pattern: str) -> np.ndarray:
        """Trance gate: one char per 16th, 'x' open, 'o' half, '.' closed."""
        pattern = pattern.replace(" ", "")
        levels = {"x": 1.0, "o": 0.5, ".": 0.08}
        curve = np.zeros(len(self.mix))
        for i in range(2 * self.steps):
            s, e = self.at(i), min(self.at(i + 1), len(curve))
            curve[s:e] = levels[pattern[i % len(pattern)]]
        curve[self.at(2 * self.steps):] = curve[self.at(self.steps)]
        return lowpass(curve, 120, 1)

    def trill(self, octave: int, rhythm: str, gain: float = 1.0, rate: float = 22.0,
              duty: float = 0.25, pan: float = 0.0, **fx) -> None:
        """Chip arpeggio: cycles the bar's triad very fast. rhythm per bar: 'x' start, '-' hold."""
        rhythm = rhythm.replace(" ", "")
        bus = np.zeros(len(self.mix))
        for i in range(self.steps):
            if rhythm[i % len(rhythm)] != "x":
                continue
            length = 1
            while length < len(rhythm) and rhythm[(i + length) % len(rhythm)] == "-":
                length += 1
            tones = [hz(t) for t in chord_notes(self.chord(i // 16), octave, 3)]
            m = int(length * self.step * SR) + 200
            idx = (np.arange(m) / SR * rate).astype(int) % 3
            freq = np.array(tones)[idx]
            self._place(bus, osc("square", freq, m, duty) * env(m, 0.002, 0.1, 0.7, 0.01) * 0.3, i)
        self._finish(bus, gain, pan, fx)

    def _pump(self, depth: float) -> np.ndarray:
        curve = np.ones(len(self.mix))
        dip = 1 - depth * np.exp(-np.arange(int(self.step * 4 * SR)) / SR / 0.09)
        for k in self.kicks:
            for offset in (0, self.length):
                s = self.at(k) + offset
                e = min(s + len(dip), len(curve))
                curve[s:e] = np.minimum(curve[s:e], dip[:e - s])
        return curve

    def notes(self, instrument: str, line: str, gain: float = 1.0, pan: float = 0.0,
              transpose_oct: int = 0, **fx) -> None:
        """Plays a melody line (repeated to fill the track)."""
        tokens = line.replace("|", " ").split()
        bus = np.zeros(len(self.mix))
        make = INSTRUMENTS[instrument]
        for i in range(self.steps):
            token = tokens[i % len(tokens)]
            if token in ("-", "."):
                continue
            length = 1
            while length < len(tokens) and tokens[(i + length) % len(tokens)] == "-":
                length += 1
            for note in token.split("+"):  # 'C4+E4' plays a dyad
                note = note[:-1] + str(int(note[-1]) + transpose_oct)
                self._place(bus, make(note, length * self.step), i)
        self._finish(bus, gain, pan, fx)

    def drums(self, instrument: str, pattern: str, gain: float = 1.0, pan: float = 0.0, **fx) -> None:
        pattern = pattern.replace(" ", "").replace("|", "")
        bus = np.zeros(len(self.mix))
        hit = INSTRUMENTS[instrument]("C4", self.step)
        soft = hit * 0.45
        for i in range(self.steps):
            c = pattern[i % len(pattern)]
            if c in "xo":
                self._place(bus, hit if c == "x" else soft, i)
                if "kick" in instrument and c == "x":
                    self.kicks.append(i)
        self._finish(bus, gain, pan, fx)

    def pad(self, instrument: str, octave: int, gain: float = 1.0, **fx) -> None:
        """Holds each bar's chord."""
        bus = np.zeros(len(self.mix))
        make = INSTRUMENTS[instrument]
        for bar in range(self.bars):
            for note in chord_notes(self.chord(bar), octave):
                self._place(bus, make(note, 16 * self.step), bar * 16)
        self._finish(bus, gain, 0.0, fx)

    def arp(self, instrument: str, octave: int, order: str, rate: int = 1, gain: float = 1.0,
            pan: float = 0.0, **fx) -> None:
        """order: chord-tone indexes per step, e.g. '0120' ('.' rests); rate: steps per note."""
        bus = np.zeros(len(self.mix))
        make = INSTRUMENTS[instrument]
        for i in range(0, self.steps, rate):
            idx = order[(i // rate) % len(order)]
            if idx == ".":
                continue
            tones = chord_notes(self.chord(i // 16), octave, 4)
            self._place(bus, make(tones[int(idx)], rate * self.step), i)
        self._finish(bus, gain, pan, fx)

    def bass(self, instrument: str, octave: int, rhythm: str, gain: float = 1.0, **fx) -> None:
        """rhythm per bar: 'r' root, 'o' octave up, 'f' fifth, '3' third, '-' hold, '.' rest."""
        rhythm = rhythm.replace(" ", "")
        bus = np.zeros(len(self.mix))
        make = INSTRUMENTS[instrument]
        for i in range(self.steps):
            c = rhythm[i % len(rhythm)]
            if c in "-.":
                continue
            length = 1
            while length < len(rhythm) and rhythm[(i + length) % len(rhythm)] == "-":
                length += 1
            tones = chord_notes(self.chord(i // 16), octave, 4)
            note = {"r": tones[0], "3": tones[1], "f": tones[2], "o": tones[3]}[c]
            self._place(bus, make(note, length * self.step), i)
        self._finish(bus, gain, 0.0, fx)

    def render(self, peak: float = 0.85) -> np.ndarray:
        loop = self.mix[self.length:2 * self.length]
        loop = highpass(loop, 28)
        return normalize(soft_clip(normalize(loop, 1.0), 1.15), peak)


def main() -> None:
    names = sys.argv[1:] or list(TRACKS)
    for name in names:
        x = TRACKS[name](Track).render()
        write_ogg(OUT / f"{name}.ogg", x)
        print(f"{name}.ogg  {len(x) / SR:.1f}s")


if __name__ == "__main__":
    main()
