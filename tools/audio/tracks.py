"""Track definitions for gen_music.py. Each function gets the Track class and returns a filled Track.

Track ids: title, boss, and one per ThemeDef id (the music follows the active art style).
Direction (Eric, 2026-10-03): fast trance/EDM with heavy bass, and chiptune leads in the style of
16-bit RPG battle themes (fast chip arpeggios, syncopated square leads). Melodies are original.
"""

FOUR = "x...x...x...x..."
OFFBEAT_HAT = "..x...x...x...x."
CLAP = "....x.......x..."
ROLL = ".rrr.rrr.rrr.rrr"  # rolling trance bass between kicks
GATE = "x.xxx.xxx.xxx.x."  # trance gate on pads


def rest(bars: int) -> str:
    return " ".join(["."] * 16 * bars)


def build(bars: int) -> str:
    """Snare roll that rises over the last bar of every `bars` bars."""
    return "." * 16 * (bars - 1) + "....o.o.oooooooo"


def title(Track):
    """Menu: mid-tempo trance in A minor with a full percussion kit under the chip lead."""
    t = Track(110, 16, ["Am", "F", "C", "G", "Am", "F", "G", "E"])
    t.drums("trance_kick", "x...x...x...x.x.x...x...x..x..x.", 1.0)
    t.drums("clap", CLAP, 0.5, reverb=(1.4, 0.3))
    t.drums("snare", "....x.......x..." + "....x.......x.oo", 0.45)
    t.drums("shaker", "xoxoxoxoxoxoxoxo", 0.6, pan=0.35)
    t.drums("open_hat", OFFBEAT_HAT, 0.4, pan=-0.2)
    t.drums("conga", "...x..x....x..x.", 0.5, pan=-0.35)
    t.drums("low_conga", "x.....x...x.....", 0.45, pan=0.3)
    t.drums("rim", "..x..x....x..x..", 0.35, pan=0.45)
    t.drums("tom", "." * 112 + "........x.x.xxxx", 0.75)
    t.drums("crash", "x" + "." * 127, 0.5)
    t.bass("roll_bass", 2, ROLL, 0.85, pump=0.5)
    t.pad("supersaw", 4, 0.45, gate=GATE, pump=0.6, width=0.015, reverb=(1.4, 0.25))
    t.trill(5, "x-------x-------", 0.2, pan=-0.35, echo=(0.75, 0.3, 0.25))
    melody = ("A5 - - E5 - - C6 - - B5 - - A5 - E5 - | F5 - - - - - A5 - C6 - - - - - - - |"
              "G5 - - E5 - - C5 - - E5 - - G5 - C6 - | B5 - - - - - D6 - - - B5 - G5 - - - |"
              "A5 - - E5 - - C6 - - B5 - - A5 - C6 - | D6 - - - C6 - - - A5 - - - F5 - A5 - |"
              "B5 - - G5 - - D6 - - B5 - - G5 - D6 - | E6 - - - - - - - G#5 - - - B5 - D6 - |")
    t.notes("chip_lead", melody, 0.7, echo=(0.75, 0.35, 0.3), reverb=(1.2, 0.2))
    t.notes("supersaw", rest(8) + " " + melody, 0.28, transpose_oct=-1, pump=0.4)
    return t


def dusk_armada(Track):
    """Main stage theme: D minor trance at a steadier tempo, kick-heavy with layered percussion."""
    t = Track(128, 16, ["Dm", "Bb", "C", "Am", "Dm", "Bb", "Gm", "A"])
    t.drums("trance_kick", "x...x...x...x..." + "x...x..xx...x.x.", 1.0)
    t.drums("clap", CLAP, 0.55, reverb=(1.2, 0.25))
    t.drums("snare", "....x.......x..." * 3 + "....x.......xoxx", 0.5)
    t.drums("shaker", "xoxoxoxoxoxoxoxo", 0.55, pan=0.35)
    t.drums("open_hat", OFFBEAT_HAT, 0.45, pan=-0.25)
    t.drums("ride", "x.x.x.x.x.x.x.x.", 0.35, pan=0.2)
    t.drums("conga", "...x..x.x..x..x.", 0.5, pan=-0.4)
    t.drums("low_conga", "x.....x...x...x.", 0.45, pan=0.4)
    t.drums("tom", "." * 112 + "........x.x.xxxx", 0.8)
    t.drums("snare", build(16), 0.5)
    t.drums("crash", "x" + "." * 127, 0.6)
    t.bass("roll_bass", 2, ".rro.rro.rro.rrf", 0.9, pump=0.55)
    t.pad("supersaw", 4, 0.4, gate=GATE, pump=0.65, width=0.015, reverb=(1.2, 0.2))
    t.trill(5, "x-------x-------", 0.2, pan=-0.4, echo=(0.75, 0.3, 0.2))
    melody = ("D5 - - D5 - - F5 - A5 - - G5 - - F5 - | F5 - - D5 - - Bb4 - D5 - F5 - Bb5 - A5 - |"
              "G5 - - E5 - - C5 - E5 - G5 - C6 - Bb5 - | A5 - - - - - E5 - - - - - C5 - E5 - |"
              "D6 - - A5 - - F5 - D5 - F5 - A5 - D6 - | C6 - - Bb5 - - A5 - F5 - - - D5 - F5 - |"
              "G5 - - Bb5 - - D6 - G6 - - F6 - - D6 - | E6 - - - C#6 - - - A5 - - - E5 - G5 - |")
    t.notes("chip_lead", melody, 0.75, echo=(0.75, 0.3, 0.25), reverb=(1.0, 0.15))
    t.notes("saw_lead", rest(8) + " " + melody, 0.38, transpose_oct=-1, echo=(0.75, 0.25, 0.2))
    return t


def outrun_grid(Track):
    """Overdrive: big-room trance with supersaw stabs."""
    t = Track(140, 8, ["Am", "F", "C", "G", "Am", "F", "G", "E"])
    t.drums("trance_kick", FOUR, 1.0)
    t.drums("big_snare", CLAP, 0.6, reverb=(1.8, 0.3))
    t.drums("clap", CLAP, 0.4)
    t.drums("open_hat", OFFBEAT_HAT, 0.5, pan=0.3)
    t.drums("snare", build(8), 0.6)
    t.bass("roll_bass", 2, ROLL, 0.9, pump=0.6)
    t.pad("supersaw", 4, 0.4, pump=0.75, width=0.018)
    t.arp("saw_stab", 4, ".0.1.2.0", 1, 0.45, pump=0.5, echo=(0.75, 0.3, 0.25))
    t.notes("saw_lead",
            "E5 - A5 - C6 - B5 - A5 - E5 - G5 - A5 - | F5 - - - A5 - - - C6 - - - A5 - F5 - |"
            "G5 - C6 - E6 - D6 - C6 - G5 - A5 - G5 - | D6 - - - B5 - - - G5 - - - D5 - G5 - |"
            "E6 - - - D6 - C6 - - - B5 - A5 - - - | C6 - - - A5 - F5 - - - A5 - C6 - - - |"
            "D6 - - - B5 - G5 - - - B5 - D6 - - - | E6 - - - - - - - D6 - - - B5 - G#5 - |",
            0.75, echo=(0.75, 0.35, 0.3), reverb=(1.5, 0.25))
    return t


def boss(Track):
    """The Matriarch: fast C minor battle theme with an octave bass ostinato."""
    t = Track(170, 16, ["Cm", "Ab", "Fm", "G", "Cm", "Ab", "Bb", "G"])
    t.drums("trance_kick", "x...x...x...x.x.", 1.0)
    t.drums("snare", "....x.......x...", 0.75, reverb=(0.9, 0.2))
    t.drums("hat", "xoxoxoxoxoxoxoxo", 0.4, pan=0.2)
    t.drums("tom", "." * 248 + "x.x.x.xx", 0.8)
    t.drums("crash", "x" + "." * 127, 0.7)
    t.bass("grit_bass", 2, "rorororororororo", 0.85, pump=0.35)
    t.pad("supersaw", 3, 0.35, gate="x..x..x.x..x..x.", pump=0.4, width=0.015)
    t.trill(5, "x-------x-------", 0.2, pan=-0.4)
    melody = ("C5 - - C5 - - Eb5 - G5 - - F5 - - Eb5 - | C5 - - - - - Ab4 - Bb4 - C5 - Eb5 - D5 - |"
              "C5 - - F5 - - Ab5 - C6 - - Bb5 - - Ab5 - | G5 - - - - - - - B5 - - - D6 - F6 - |"
              "Eb6 - - D6 - - C6 - G5 - - Ab5 - - G5 - | Eb5 - - F5 - - G5 - Ab5 - - G5 - - F5 - |"
              "D5 - - Eb5 - - F5 - Bb5 - - Ab5 - - G5 - | G5 - - - F5 - - - D5 - - - B4 - - - |")
    t.notes("chip_lead", melody, 0.8, echo=(0.5, 0.25, 0.2))
    t.notes("brass", rest(8) + " " + melody, 0.55, transpose_oct=-1, drive=1.3)
    return t


def cold_hologram(Track):
    """Lock-On: icy uplifting trance, FM bell arps, precise chip lead."""
    t = Track(145, 8, ["Em", "Cmaj7", "G", "D", "Em", "Cmaj7", "Am", "B"])
    t.drums("trance_kick", FOUR, 0.9)
    t.drums("clap", CLAP, 0.4, reverb=(1.6, 0.3))
    t.drums("open_hat", OFFBEAT_HAT, 0.45, pan=0.35)
    t.drums("snare", build(8), 0.45)
    t.bass("roll_bass", 2, ROLL, 0.8, pump=0.55)
    t.pad("supersaw", 4, 0.35, gate=GATE, pump=0.6, width=0.015, lowpass=3500)
    t.arp("bell", 5, "0213", 1, 0.4, pan=-0.3, echo=(0.75, 0.4, 0.3))
    t.notes("chip_lead",
            "B5 - - G5 - - E5 - B5 - - - E6 - - - | D6 - - B5 - - G5 - E5 - - - G5 - - - |"
            "D6 - - B5 - - G5 - D6 - - - G6 - - - | F#6 - - - E6 - - - D6 - - - A5 - - - |"
            "B5 - - G5 - - E5 - B5 - - - E6 - - - | E6 - - D6 - - B5 - G5 - - - B5 - - - |"
            "C6 - - B5 - - A5 - E5 - - - A5 - - - | F#6 - - - - - - - D#6 - - - B5 - - - |",
            0.7, pan=0.15, echo=(0.75, 0.4, 0.35), reverb=(1.8, 0.3))
    return t


def particle_storm(Track):
    """Chain Reaction: drum and bass with a reese bass and racing chip arpeggios."""
    t = Track(174, 8, ["Fm", "Db", "Eb", "C"])
    t.drums("trance_kick", "x.........x.....", 1.0)
    t.drums("snare", "....x..o.o..x...", 0.85)
    t.drums("hat", "xoxoxoxoxoxoxoxo", 0.4, pan=0.3)
    t.bass("reese", 2, "r-------r---o---", 0.9)
    t.trill(5, "x---x---x---x---", 0.2, rate=28, pan=-0.4, echo=(0.375, 0.4, 0.3))
    t.notes("chip_lead",
            "F5 Ab5 C6 F6 C6 Ab5 F5 Ab5 C6 - Db6 - C6 - Ab5 - | F5 Ab5 Db6 F6 Db6 Ab5 F5 Ab5 Db6 - Eb6 - F6 - Db6 - |"
            "G5 Bb5 Eb6 G6 Eb6 Bb5 G5 Bb5 Eb6 - F6 - G6 - Bb6 - | C6 - - - E6 - - - G6 - - - E6 - C6 - |",
            0.65, echo=(0.75, 0.3, 0.3))
    t.notes("riser", " ".join(["."] * 112 + ["C4"] + ["-"] * 15), 0.7)
    return t


def pocket_four(Track):
    """Graze: four-channel handheld chip, fast and driving."""
    t = Track(160, 8, ["Am", "Dm", "G", "C", "F", "Dm", "E", "E"])
    crush = (5, 2)
    t.drums("chip_kick", FOUR, 0.9, crush=crush)
    t.drums("chip_snare", "....x.......x..x", 0.7, crush=crush)
    t.drums("chip_noise", "x.x.x.x.x.x.x.xx", 0.55, crush=crush)
    t.bass("gb_wave", 3, "rrorrrorrrorrror", 0.8, crush=crush)
    t.trill(4, "x-------x-------", 0.3, rate=20, pan=-0.5, crush=crush)
    t.notes("pulse_half",
            "A5 - C6 - E6 - C6 - A5 - E5 - A5 - C6 - | D6 - - - F6 - - - A5 - - - D6 - C6 - |"
            "B5 - D6 - G6 - D6 - B5 - G5 - B5 - D6 - | E6 - - - C6 - - - G5 - - - C6 - - - |"
            "A5 - C6 - F6 - C6 - A5 - F5 - A5 - C6 - | D6 - - - A5 - - - F5 - - - A5 - D6 - |"
            "E6 - - - D6 - - - B5 - - - G#5 - - - | E5 - G#5 - B5 - E6 - G#6 - - - B6 - - - |",
            0.55, pan=0.3, crush=crush)
    return t


def arcade_classic(Track):
    """Arcade '81: bright, dry square-wave tune in C over a four-on-the-floor chip beat."""
    t = Track(155, 8, ["C", "Am", "F", "G", "C", "Am", "Dm", "G"])
    t.drums("chip_kick", FOUR, 0.8)
    t.drums("chip_snare", "....x.......x...", 0.6)
    t.drums("chip_noise", OFFBEAT_HAT, 0.5)
    t.bass("square_bass", 2, ROLL, 0.75)
    t.trill(4, "x-------x-------", 0.28, rate=18, pan=-0.3)
    t.notes("pulse_half",
            "C5 E5 G5 C6 - - G5 - E5 G5 C6 E6 - - C6 - | A5 - E5 - C5 - E5 - A5 - - - G5 - A5 - |"
            "F5 A5 C6 F6 - - C6 - A5 - F5 - A5 - C6 - | B5 - - - D6 - - - G5 - - - B5 - D6 - |"
            "E6 - D6 - C6 - G5 - E5 - G5 - C6 - - - | C6 - B5 - A5 - E5 - C5 - E5 - A5 - - - |"
            "D6 - C6 - A5 - F5 - D5 - F5 - A5 - D6 - | B5 - - - - - - - G5 - A5 - B5 - - - |",
            0.55, pan=0.2, echo=(0.5, 0.15, 0.15))
    return t


TRACKS = {f.__name__: f for f in (title, dusk_armada, outrun_grid, boss, cold_hologram,
                                  particle_storm, pocket_four, arcade_classic)}
