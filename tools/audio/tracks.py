"""Track definitions for gen_music.py. Each function gets the Track class and returns a filled Track.

Track ids: title, boss, and one per ThemeDef id (the music follows the active art style).
"""


def title(Track):
    t = Track(84, 8, ["Am", "F", "C", "G", "Am", "F", "Dm", "E"])
    t.pad("warm_pad", 3, 0.9, reverb=(1.6, 0.4), width=0.012)
    t.bass("sub_bass", 2, "r---------------", 0.7)
    t.arp("bell", 5, "0123", 2, 0.35, pan=0.3, echo=(0.75, 0.4, 0.35), reverb=(1.5, 0.3))
    t.drums("kick", "x.........x.....", 0.35)
    t.drums("hat", "..o...o...o...o.", 0.5, pan=-0.3)
    t.notes("tri_lead", "E5 - - - - - D5 - C5 - - - B4 - A4 - | C5 - - - - - - - A4 - - - - - - - |"
            "G4 - - - C5 - - - E5 - - - D5 - C5 - | D5 - - - - - - - B4 - - - G4 - - - |"
            "A5 - - - G5 - E5 - - - D5 - E5 - - - | F5 - - - E5 - C5 - - - - - A4 - C5 - |"
            "D5 - - - F5 - - - A5 - - - G5 - F5 - | E5 - - - - - - - G#5 - - - B5 - - -",
            0.55, echo=(1.5, 0.35, 0.3), reverb=(1.4, 0.3))
    return t


def dusk_armada(Track):
    """Main stage theme: driving dusk chiptune-synth in D minor."""
    t = Track(144, 16, ["Dm", "Bb", "C", "Am", "Dm", "Bb", "Gm", "A"])
    t.drums("kick", "x.......x.x.....", 0.9)
    t.drums("snare", "....x.......x...", 0.7, reverb=(0.8, 0.15))
    t.drums("hat", "o.x.o.x.o.x.o.x.", 0.55, pan=0.25)
    t.drums("crash", "x" + "." * 127, 0.6)
    t.bass("saw_bass", 2, "r.r.o.r.r.r.o.r.", 0.8)
    t.pad("saw_pad", 3, 0.45, width=0.015, reverb=(1.2, 0.2))
    t.arp("chip_arp", 4, "0122", 1, 0.3, pan=-0.35, echo=(0.5, 0.2, 0.2))
    t.notes("pulse_lead",
            "D5 - - A4 D5 - F5 - A5 - - - G5 - F5 - | F5 - E5 - D5 - - - Bb4 - - - C5 - D5 - |"
            "E5 - - C5 E5 - G5 - - - F5 - E5 - C5 - | E5 - - - - - - - . . A4 - C5 - E5 - |"
            "F5 - - D5 F5 - A5 - - - G5 - F5 - E5 - | D5 - - - F5 - - - Bb5 - - - A5 - G5 - |"
            "G5 - - - Bb5 - - - D6 - - - C6 - Bb5 - | A5 - - - - - - - C#6 - - - E6 - - - |"
            "A5 - A5 - G5 - F5 - G5 - A5 - - - D5 - | F5 - F5 - E5 - D5 - E5 - F5 - - - Bb4 - |"
            "C5 - E5 - G5 - C6 - Bb5 - A5 - G5 - E5 - | A5 - - - - - - - - - - - . . . . |"
            "D6 - - - A5 - - - F5 - - - D5 - F5 - | Bb5 - - - F5 - - - D5 - - - F5 - Bb5 - |"
            "A5 - G5 - F5 - G5 - - - Bb5 - A5 - G5 - | A5 - - - - - - - E5 - - - C#5 - - -",
            0.75, echo=(0.75, 0.3, 0.25), reverb=(1.0, 0.15))
    return t


def outrun_grid(Track):
    """Overdrive: synthwave with a pumping gated pad."""
    t = Track(128, 8, ["Am", "F", "C", "G", "Am", "F", "G", "E"])
    t.drums("kick", "x...x...x...x...", 1.0)
    t.drums("big_snare", "....x.......x...", 0.75, reverb=(1.8, 0.35))
    t.drums("clap", "....x.......x...", 0.35)
    t.drums("open_hat", "..x...x...x...x.", 0.5, pan=0.3)
    t.bass("saw_bass", 2, "rrrorrrorrrorrro", 0.75, pump=0.6)
    t.pad("gated_pad", 4, 0.6, pump=0.75, width=0.018)
    t.arp("pluck", 4, "0123", 1, 0.45, pan=-0.3, echo=(0.75, 0.35, 0.3))
    t.notes("saw_lead",
            "E5 - - - - - - - A5 - - - G5 - E5 - | F5 - - - - - - - C5 - - - - - - - |"
            "G5 - - - - - - - E5 - - - D5 - C5 - | D5 - - - - - - - - - - - B4 - D5 - |"
            "E5 - - - A5 - - - C6 - - - B5 - A5 - | C6 - - - - - - - A5 - - - F5 - A5 - |"
            "B5 - - - - - - - D6 - - - B5 - G5 - | G#5 - - - - - - - - - - - B5 - - -",
            0.8, echo=(0.75, 0.35, 0.3), reverb=(1.6, 0.25))
    return t


def boss(Track):
    """The Matriarch: heavy C minor."""
    t = Track(152, 8, ["Cm", "Ab", "Fm", "G", "Cm", "Ab", "Fm", "G7"])
    t.drums("kick", "x..x..x.x..x..x.", 1.0)
    t.drums("snare", "....x.......x..x", 0.8, reverb=(0.9, 0.2))
    t.drums("hat", "o.o.o.o.o.o.o.o.", 0.5, pan=0.2)
    t.drums("tom", "." * 112 + "........x.x.x.xx", 0.8)
    t.drums("crash", "x" + "." * 127, 0.7)
    t.bass("grit_bass", 2, "r.rr.rr.r.rro.r.", 0.9)
    t.pad("saw_pad", 3, 0.5, width=0.015)
    t.arp("chip_arp", 5, "0120", 1, 0.22, pan=-0.4, echo=(0.5, 0.2, 0.2))
    t.notes("saw_lead",
            "C5 - - - - - Eb5 - D5 - - - C5 - G4 - | Ab4 - - - - - - - G4 - - - Ab4 - Bb4 - |"
            "C5 - - - - - Ab5 - G5 - - - F5 - Eb5 - | D5 - - - - - - - B4 - - - - - - - |"
            "G5 - - - - - C6 - B5 - - - G5 - Eb5 - | F5 - - - Eb5 - - - C5 - - - Eb5 - F5 - |"
            "Ab5 - - - G5 - - - F5 - - - Eb5 - D5 - | D5 - - - - - - - F5 - - - B5 - - -",
            0.8, drive=1.5, echo=(0.75, 0.25, 0.2), reverb=(1.0, 0.15))
    return t


def cold_hologram(Track):
    """Lock-On: icy and precise. FM bells, sine bass, sparse glass lead."""
    t = Track(140, 8, ["Em", "Cmaj7", "G", "Dsus2", "Em", "Cmaj7", "Am", "B"])
    t.drums("kick", "x.....x...x.....", 0.8)
    t.drums("clap", "....x.......x...", 0.45, reverb=(1.5, 0.3))
    t.drums("hat", "..x...x...x...xo", 0.5, pan=0.4)
    t.bass("sub_bass", 2, "r.......r...r...", 0.9)
    t.arp("bell", 5, "0213", 1, 0.4, pan=-0.3, echo=(0.75, 0.4, 0.35), reverb=(1.6, 0.3))
    t.notes("glass",
            "B5 - - - - - - - E6 - - - - - - - | D6 - - - - - - - B5 - - - G5 - - - |"
            "D6 - - - - - - - G6 - - - - - - - | F#6 - - - - - - - E6 - - - D6 - - - |"
            "B5 - - - - - - - E6 - - - G6 - - - | F#6 - - - - - - - E6 - - - B5 - - - |"
            "C6 - - - - - - - E6 - - - A6 - - - | F#6 - - - - - - - D#6 - - - B5 - - -",
            0.8, pan=0.2, echo=(1.0, 0.45, 0.4), reverb=(2.0, 0.4))
    return t


def particle_storm(Track):
    """Chain Reaction: fast breakbeat chaos in F minor."""
    t = Track(165, 8, ["Fm", "Db", "Eb", "C"])
    t.drums("kick", "x.....x...x.x...", 1.0)
    t.drums("snare", "....x..x.x..x..o", 0.8)
    t.drums("hat", "xoxoxoxoxoxoxoxo", 0.45, pan=0.3)
    t.bass("grit_bass", 2, "r.ro.rr.r.ro.rf.", 0.9)
    t.arp("pluck", 5, "0123210", 1, 0.4, pan=-0.4, echo=(0.375, 0.5, 0.4), drive=1.4)
    t.notes("pulse_thin",
            "C6 . C6 . Ab5 . F5 . C6 . Db6 . C6 . Ab5 . | F5 . Ab5 . Db6 . F6 . Eb6 . Db6 . Ab5 . F5 . |"
            "G5 . Bb5 . Eb6 . G6 . F6 . Eb6 . Bb5 . G5 . | E6 - - - C6 - - - G5 - - - E5 - - -",
            0.7, echo=(0.75, 0.3, 0.3))
    t.notes("riser", " ".join(["."] * 112 + ["C4"] + ["-"] * 15), 0.8)
    return t


def pocket_four(Track):
    """Graze: four-channel handheld sound (2 pulses, wave, noise), crushed."""
    t = Track(150, 8, ["Am", "Dm", "G", "C", "F", "Dm", "E", "E"])
    crush = (5, 2)
    t.drums("chip_kick", "x.......x.......", 0.8, crush=crush)
    t.drums("chip_snare", "....x.......x...", 0.7, crush=crush)
    t.drums("chip_noise", "x.x.x.x.x.x.x.xx", 0.6, crush=crush)
    t.bass("gb_wave", 3, "r.r.o.r.r.f.o.r.", 0.8, crush=crush)
    t.arp("pulse_thin", 4, "012.", 1, 0.3, pan=-0.5, crush=crush)
    t.notes("pulse_half",
            "A4 - C5 - E5 - A5 - G5 - E5 - C5 - E5 - | F5 - - - D5 - F5 - A5 - - - F5 - D5 - |"
            "G5 - - - B4 - D5 - G5 - F5 - D5 - B4 - | C5 - E5 - G5 - C6 - - - - - G5 - - - |"
            "A5 - - - F5 - A5 - C6 - - - A5 - F5 - | D5 - F5 - A5 - D6 - C6 - A5 - F5 - D5 - |"
            "E5 - - - G#5 - - - B5 - - - E6 - - - | D6 - C6 - B5 - G#5 - E5 - - - - - . .",
            0.6, pan=0.3, crush=crush)
    return t


def arcade_classic(Track):
    """Arcade '81: bright, dry, three-voice square chip tune in C."""
    t = Track(132, 8, ["C", "Am", "F", "G", "C", "Am", "Dm", "G"])
    t.drums("chip_kick", "x.......x...x...", 0.7)
    t.drums("chip_snare", "....x.......x...", 0.6)
    t.drums("chip_noise", "..x...x...x...x.", 0.5)
    t.bass("square_bass", 2, "r.r.f.r.r.r.f.o.", 0.7)
    t.arp("chip_arp", 4, "0120", 2, 0.35, pan=-0.3)
    t.notes("pulse_half",
            "C5 E5 G5 C6 - - G5 - E5 G5 C6 E6 - - C6 - | A5 - E5 - C5 - E5 - A5 - - - G5 - A5 - |"
            "F5 A5 C6 F6 - - C6 - A5 - F5 - A5 - C6 - | B5 - - - D6 - - - G5 - - - B5 - D6 - |"
            "E6 - D6 - C6 - G5 - E5 - G5 - C6 - - - | C6 - B5 - A5 - E5 - C5 - E5 - A5 - - - |"
            "D6 - C6 - A5 - F5 - D5 - F5 - A5 - D6 - | B5 - - - - - - - G5 - A5 - B5 - - -",
            0.55, pan=0.2, echo=(0.5, 0.15, 0.15))
    return t


TRACKS = {f.__name__: f for f in (title, dusk_armada, outrun_grid, boss, cold_hologram,
                                  particle_storm, pocket_four, arcade_classic)}
