"""Track definitions for gen_music.py. Each function gets the Track class and returns a filled Track.

Track ids: title, the Sector 1 soundtrack (act1-act4 for stage groups, miniboss, boss), and one
per ThemeDef id (fallback when a stage names no track). StageDef.music picks the track per stage.
Loops stay ~25-35 s: web builds decode each playing track into memory (~0.35 MB per second).
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


def fill(bars: int) -> str:
    """Tom fill over the last half bar of every `bars` bars."""
    return "." * (16 * bars - 8) + "x.x.xxxx"


def kit(t, bars: int, gain: float = 1.0, congas: bool = True) -> None:
    """Shared trance kit for the sector tracks: kick, clap, hats, shaker, fills and a crash per section."""
    t.drums("trance_kick", "x...x...x...x..." * 7 + "x...x..xx...x.x.", gain)
    t.drums("clap", CLAP, 0.55 * gain, reverb=(1.2, 0.25))
    t.drums("open_hat", OFFBEAT_HAT, 0.42 * gain, pan=-0.25)
    t.drums("shaker", "xoxoxoxoxoxoxoxo", 0.5 * gain, pan=0.35)
    if congas:
        t.drums("conga", "...x..x.x..x..x.", 0.45 * gain, pan=-0.4)
        t.drums("low_conga", "x.....x...x...x.", 0.4 * gain, pan=0.4)
    t.drums("snare", build(8), 0.5 * gain)
    t.drums("tom", fill(bars), 0.75 * gain)
    t.drums("crash", "x" + "." * 127, 0.55 * gain)


# --- Sector 1 soundtrack: one track per stage group, rising in tempo and weight ----------------

def act1(Track):
    """Stages 1-4, Dusk Patrol: E minor, bright and open, the easy opener."""
    t = Track(124, 16, ["Em", "C", "G", "D", "Em", "C", "Am", "B"])
    kit(t, 16, 0.95)
    t.bass("roll_bass", 2, ROLL, 0.85, pump=0.5)
    t.pad("supersaw", 4, 0.38, gate=GATE, pump=0.6, width=0.015, reverb=(1.3, 0.25))
    t.trill(5, "x-------x-------", 0.18, pan=-0.35, echo=(0.75, 0.3, 0.2))
    a = ("E5 - - G5 - - B5 - A5 - G5 - F#5 - E5 - | G5 - - - E5 - - - C5 - E5 - G5 - - - |"
         "D5 - - G5 - - B5 - D6 - - - B5 - G5 - | A5 - - - F#5 - - - D5 - - - . . . . |"
         "E5 - - G5 - - B5 - E6 - - - D6 - B5 - | C6 - - B5 - - G5 - E5 - - - G5 - C6 - |"
         "A5 - - C6 - - E6 - D6 - C6 - B5 - A5 - | B5 - - - - - - - D#5 - - - F#5 - A5 - |")
    b = ("B5 - E6 - B5 - G5 - E5 - G5 - B5 - E6 - | C6 - - - B5 - G5 - - - E5 - G5 - - - |"
         "D6 - G6 - D6 - B5 - G5 - B5 - D6 - G6 - | F#6 - - - E6 - D6 - - - A5 - - - . . |"
         "G6 - - F#6 - - E6 - B5 - - - E6 - - - | E6 - - D6 - - C6 - G5 - - - C6 - - - |"
         "C6 - - B5 - - A5 - E5 - A5 - C6 - E6 - | D#6 - - - - - - - F#6 - - - B5 - - - |")
    t.notes("chip_lead", a + b, 0.72, echo=(0.75, 0.3, 0.25), reverb=(1.0, 0.15))
    t.notes("saw_lead", rest(8) + " " + b, 0.34, transpose_oct=-1, echo=(0.75, 0.25, 0.2))
    return t


def act2(Track):
    """Stages 6-9, Rising Swarm: G minor, faster, chip runs in the second half."""
    t = Track(132, 16, ["Gm", "Eb", "Bb", "F", "Gm", "Eb", "Cm", "D"])
    kit(t, 16)
    t.drums("ride", "x.x.x.x.x.x.x.x.", 0.3, pan=0.2)
    t.bass("roll_bass", 2, ".rro.rro.rro.rrf", 0.9, pump=0.55)
    t.pad("supersaw", 4, 0.38, gate=GATE, pump=0.65, width=0.015, reverb=(1.2, 0.2))
    t.trill(5, "x-------x-------", 0.2, pan=-0.4, echo=(0.75, 0.3, 0.2))
    a = ("G5 - - Bb5 - - D6 - C6 - Bb5 - A5 - G5 - | Bb5 - - - G5 - - - Eb5 - G5 - Bb5 - - - |"
         "F5 - - Bb5 - - D6 - F6 - - - D6 - Bb5 - | C6 - - - A5 - - - F5 - - - A5 - C6 - |"
         "D6 - - Bb5 - - G5 - D6 - - - G6 - - - | G6 - - F6 - - Eb6 - Bb5 - - - G5 - Bb5 - |"
         "C6 - - Eb6 - - G6 - F6 - Eb6 - D6 - C6 - | D6 - - - - - - - F#5 - - - A5 - C6 - |")
    b = ("G5 Bb5 D6 G6 - - D6 - Bb5 - G5 - D6 - - - | Eb6 - - D6 - - Bb5 - G5 - - - Bb5 - Eb6 - |"
         "F5 Bb5 D6 F6 - - D6 - Bb5 - F5 - D6 - - - | C6 - - A5 - - F5 - A5 - C6 - F6 - - - |"
         "G6 - - F6 - - D6 - Bb5 - - - D6 - G6 - | Bb6 - - G6 - - Eb6 - Bb5 - - - G6 - - - |"
         "Eb6 - - D6 - - C6 - G5 - C6 - Eb6 - G6 - | F#6 - - - - - - - A6 - - - F#6 - D6 - |")
    t.notes("chip_lead", a + b, 0.74, echo=(0.75, 0.3, 0.25), reverb=(1.0, 0.15))
    t.notes("saw_lead", rest(8) + " " + b, 0.36, transpose_oct=-1, echo=(0.75, 0.25, 0.2))
    return t


def act3(Track):
    """Stages 11-14, Deep Armada: B minor, darker, gritty bass under a low lead."""
    t = Track(136, 16, ["Bm", "G", "D", "A", "Bm", "G", "Em", "F#"])
    kit(t, 16)
    t.drums("rim", "..x..x....x..x..", 0.3, pan=0.45)
    t.bass("grit_bass", 2, ".rro.rro.rro.rro", 0.8, pump=0.5)
    t.bass("sub_bass", 1, "r...r...r...r...", 0.5)
    t.pad("supersaw", 4, 0.34, gate=GATE, pump=0.65, width=0.015, lowpass=4000, reverb=(1.4, 0.25))
    t.arp("bell", 5, "0213", 1, 0.3, pan=-0.3, echo=(0.75, 0.35, 0.25))
    a = ("B4 - - B4 - - D5 - F#5 - - E5 - - D5 - | D5 - - B4 - - G4 - B4 - D5 - G5 - F#5 - |"
         "F#5 - - D5 - - A4 - D5 - F#5 - A5 - G5 - | E5 - - - - - C#5 - - - A4 - C#5 - E5 - |"
         "B5 - - F#5 - - D5 - B4 - D5 - F#5 - B5 - | A5 - - G5 - - D5 - B4 - - - D5 - G5 - |"
         "G5 - - F#5 - - E5 - B4 - E5 - G5 - B5 - | A#5 - - - - - - - F#5 - - - C#6 - - - |")
    b = ("F#5 B5 D6 F#6 - - D6 - B5 - F#5 - B5 - D6 - | G6 - - F#6 - - D6 - B5 - - - G5 - B5 - |"
         "A5 D6 F#6 A6 - - F#6 - D6 - A5 - D6 - F#6 - | E6 - - - C#6 - - - A5 - - - C#6 - E6 - |"
         "D6 - - C#6 - - B5 - F#5 - - - B5 - D6 - | B5 - - A5 - - G5 - D5 - - - G5 - B5 - |"
         "E6 - - D6 - - B5 - G5 - B5 - E6 - G6 - | F#6 - - - E6 - - - C#6 - - - A#5 - - - |")
    t.notes("chip_lead", a + b, 0.74, echo=(0.75, 0.3, 0.25), reverb=(1.0, 0.15))
    t.notes("brass", rest(8) + " " + b, 0.4, transpose_oct=-1, drive=1.2)
    return t


def act4(Track):
    """Stages 16-19, Overkill: F minor, the heaviest and fastest stage track."""
    t = Track(142, 16, ["Fm", "Db", "Ab", "Eb", "Fm", "Db", "Bbm", "C"])
    kit(t, 16, congas=False)
    t.drums("big_snare", CLAP, 0.45, reverb=(1.6, 0.3))
    t.drums("ride", "x.x.x.x.x.x.x.x.", 0.3, pan=0.2)
    t.bass("roll_bass", 2, ROLL, 0.9, pump=0.6)
    t.bass("sub_bass", 1, "r...r...r...r...", 0.45)
    t.pad("supersaw", 4, 0.4, pump=0.75, width=0.018)
    t.arp("saw_stab", 4, ".0.1.2.0", 1, 0.35, pump=0.5, echo=(0.75, 0.3, 0.2))
    a = ("F5 - - Ab5 - - C6 - F6 - - Eb6 - - C6 - | Db6 - - - Ab5 - - - F5 - Ab5 - Db6 - - - |"
         "Eb6 - - C6 - - Ab5 - Eb5 - Ab5 - C6 - Eb6 - | G5 - - - Bb5 - - - Eb6 - - - G6 - - - |"
         "Ab6 - - G6 - - F6 - C6 - - - F6 - Ab6 - | F6 - - Eb6 - - Db6 - Ab5 - - - Db6 - F6 - |"
         "Db6 - - C6 - - Bb5 - F5 - Bb5 - Db6 - F6 - | E6 - - - - - - - G6 - - - Bb6 - - - |")
    b = ("F5 Ab5 C6 F6 Ab6 F6 C6 Ab5 F5 - - - C6 - - - | Db5 F5 Ab5 Db6 F6 Db6 Ab5 F5 Db6 - - - F6 - - - |"
         "Eb5 Ab5 C6 Eb6 Ab6 Eb6 C6 Ab5 Eb6 - - - C6 - - - | G6 - - F6 - - Eb6 - Bb5 - - - G5 - Bb5 - |"
         "C6 - - - Ab5 - - - F6 - - - Eb6 - C6 - | Db6 - - - F6 - - - Ab6 - - - F6 - Db6 - |"
         "Bb5 - - C6 - - Db6 - F6 - - Eb6 - - Db6 - | C6 - - - E6 - - - G6 - - - C7 - - - |")
    t.notes("chip_lead", a + b, 0.74, echo=(0.75, 0.3, 0.25), reverb=(1.0, 0.15))
    t.notes("saw_lead", rest(8) + " " + b, 0.36, transpose_oct=-1, echo=(0.75, 0.25, 0.2))
    return t


def miniboss(Track):
    """Mini-bosses (stages 5, 8, 15, 18): A minor battle theme with a driving octave bass."""
    t = Track(156, 16, ["Am", "F", "Dm", "E", "Am", "F", "G", "E"])
    t.drums("trance_kick", "x...x...x...x.x.", 1.0)
    t.drums("snare", "....x.......x...", 0.7, reverb=(0.9, 0.2))
    t.drums("hat", "xoxoxoxoxoxoxoxo", 0.4, pan=0.2)
    t.drums("open_hat", OFFBEAT_HAT, 0.3, pan=-0.25)
    t.drums("snare", build(8), 0.5)
    t.drums("tom", fill(8), 0.8)
    t.drums("crash", "x" + "." * 127, 0.65)
    t.bass("grit_bass", 2, "rorororororororo", 0.85, pump=0.35)
    t.pad("supersaw", 3, 0.32, gate="x..x..x.x..x..x.", pump=0.4, width=0.015)
    t.trill(5, "x-------x-------", 0.2, pan=-0.4)
    a = ("A4 - - A4 - - C5 - E5 - - D5 - - C5 - | A4 - - - - - F4 - G4 - A4 - C5 - B4 - |"
         "A4 - - D5 - - F5 - A5 - - G5 - - F5 - | E5 - - - - - - - G#5 - - - B5 - D6 - |"
         "C6 - - B5 - - A5 - E5 - - F5 - - E5 - | C5 - - D5 - - E5 - F5 - - E5 - - D5 - |"
         "B4 - - C5 - - D5 - G5 - - F5 - - D5 - | E5 - - - D5 - - - B4 - - - G#4 - - - |")
    b = ("A5 C6 E6 A6 E6 C6 A5 - E6 - - - C6 - A5 - | F5 A5 C6 F6 C6 A5 F5 - C6 - - - A5 - F5 - |"
         "D6 - - F6 - - A6 - G6 - F6 - E6 - D6 - | E6 - - - B5 - - - G#5 - - - E5 - - - |"
         "A5 - - - C6 - - - E6 - - - A6 - - - | A6 - - G6 - - F6 - C6 - - - F6 - - - |"
         "G6 - - F6 - - D6 - B5 - D6 - F6 - G6 - | G#6 - - - - - - - B6 - - - E6 - - - |")
    t.notes("chip_lead", a + b, 0.78, echo=(0.5, 0.25, 0.2))
    t.notes("brass", a + rest(8), 0.5, transpose_oct=-1, drive=1.3)
    return t


def boss(Track):
    """The Matriarch (stages 10 and 20): fast C minor battle theme in three sections."""
    t = Track(170, 24, ["Cm", "Ab", "Fm", "G", "Cm", "Ab", "Bb", "G"])
    t.drums("trance_kick", "x...x...x...x.x.", 1.0)
    t.drums("snare", "....x.......x...", 0.75, reverb=(0.9, 0.2))
    t.drums("hat", "xoxoxoxoxoxoxoxo", 0.4, pan=0.2)
    t.drums("open_hat", rest(8).replace(" ", "") + OFFBEAT_HAT * 16, 0.3, pan=-0.25)
    t.drums("snare", build(8), 0.55)
    t.drums("tom", fill(8), 0.8)
    t.drums("crash", "x" + "." * 127, 0.7)
    t.bass("grit_bass", 2, "rorororororororo", 0.85, pump=0.35)
    t.pad("supersaw", 3, 0.35, gate="x..x..x.x..x..x.", pump=0.4, width=0.015)
    t.trill(5, "x-------x-------", 0.2, pan=-0.4)
    a = ("C5 - - C5 - - Eb5 - G5 - - F5 - - Eb5 - | C5 - - - - - Ab4 - Bb4 - C5 - Eb5 - D5 - |"
         "C5 - - F5 - - Ab5 - C6 - - Bb5 - - Ab5 - | G5 - - - - - - - B5 - - - D6 - F6 - |"
         "Eb6 - - D6 - - C6 - G5 - - Ab5 - - G5 - | Eb5 - - F5 - - G5 - Ab5 - - G5 - - F5 - |"
         "D5 - - Eb5 - - F5 - Bb5 - - Ab5 - - G5 - | G5 - - - F5 - - - D5 - - - B4 - - - |")
    c = ("G5 - G5 - C6 - G5 - Eb6 - D6 - C6 - G5 - | Ab5 - Ab5 - C6 - Ab5 - Eb6 - - - C6 - - - |"
         "F5 - Ab5 - C6 - F6 - Eb6 - C6 - Ab5 - F5 - | G5 - - - B5 - - - D6 - - - F6 - - - |"
         "Eb6 G6 C7 G6 Eb6 C6 G5 C6 Eb6 - - - G6 - - - | Eb6 Ab6 C7 Ab6 Eb6 C6 Ab5 C6 Eb6 - - - C6 - - - |"
         "D6 F6 Bb6 F6 D6 Bb5 F5 Bb5 D6 - - - F6 - - - | G6 - - - F6 - - - D6 - - - B5 - - - |")
    t.notes("chip_lead", a + a + c, 0.8, echo=(0.5, 0.25, 0.2))
    t.notes("brass", rest(8) + " " + a + c, 0.55, transpose_oct=-1, drive=1.3)
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


TRACKS = {f.__name__: f for f in (title, act1, act2, act3, act4, miniboss, boss, dusk_armada, outrun_grid, cold_hologram,
                                  particle_storm, pocket_four, arcade_classic)}
