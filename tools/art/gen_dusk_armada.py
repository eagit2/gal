#!/usr/bin/env python3
"""Generates the Dusk Armada (concept P2) pixel art into assets/art/dusk_armada/.

Sprites are authored at 1x for the 270x480 pixel grid and shown at 2x with nearest filtering.
Each sprite is a list of frames; each frame is rows of palette keys ('.' is transparent).
Every sprite gets a 1px dark outline. Frames are laid out left to right (Sprite2D hframes).

Run: python3 tools/art/gen_dusk_armada.py   (needs Pillow)
"""
import math
import random
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets" / "art" / "dusk_armada"
OUTLINE = "#1a0f2e"
# Reserved for enemy bullets only (docs/decisions.md). Nothing else may use it.
BULLET_RED = "#ff4d6d"


def rgba(hex_color: str, alpha: int = 255) -> tuple:
    """'#rrggbb' or '#rrggbbaa'."""
    h = hex_color.lstrip("#")
    a = int(h[6:8], 16) if len(h) == 8 else alpha
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def frame_image(rows: list, pal: dict, outline: bool = True) -> Image.Image:
    h, w = len(rows), len(rows[0])
    assert all(len(r) == w for r in rows), rows
    o = 1 if outline else 0
    img = Image.new("RGBA", (w + 2 * o, h + 2 * o), (0, 0, 0, 0))

    def on(i: int, j: int) -> bool:
        return 0 <= j < h and 0 <= i < w and rows[j][i] != "."

    if outline:
        for j in range(-1, h + 1):
            for i in range(-1, w + 1):
                if not on(i, j) and (on(i - 1, j) or on(i + 1, j) or on(i, j - 1) or on(i, j + 1)):
                    img.putpixel((i + o, j + o), rgba(OUTLINE))
    for j in range(h):
        for i in range(w):
            if on(i, j):
                img.putpixel((i + o, j + o), rgba(pal[rows[j][i]]))
    return img


def strip(frames: list) -> Image.Image:
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for k, f in enumerate(frames):
        out.paste(f, (k * w, 0))
    return out


DAMAGE_PAL = {"K": OUTLINE, "X": "#4a3046", "E": "#ff9f62"}


def damaged(frames: list, seed: int) -> list:
    """Battle-damaged copies of `frames`: a crack, scorch marks and a chipped edge,
    identical across frames so the damage doesn't flicker."""
    rnd = random.Random(seed)
    h, w = len(frames[0]), len(frames[0][0])
    body = [(i, j) for j in range(h) for i in range(w) if frames[0][j][i] != "."]
    marks = {}
    i, j = rnd.choice([b for b in body if abs(b[0] - w / 2) < w / 4] or body)
    for n in range(rnd.randint(6, 8)):  # crack: short random walk, glowing embers inside
        marks[(i, j)] = "E" if n % 3 == 1 else "K"
        i, j = i + rnd.choice((-1, 0, 1)), j + rnd.choice((-1, 1))
    for b in rnd.sample(body, max(2, len(body) // 9)):
        marks.setdefault(b, "X" if rnd.random() < 0.8 else "E")
    edge = [b for b in body if b[0] in (0, w - 1) or b[1] in (0, h - 1)]
    for b in rnd.sample(edge, min(2, len(edge))):
        marks[b] = "."
    out = []
    for f in frames:
        rows = [list(r) for r in f]
        for (x, y), k in marks.items():
            if 0 <= y < h and 0 <= x < w and rows[y][x] != ".":
                rows[y][x] = k
        out.append(["".join(r) for r in rows])
    return out


def sprite(name: str, frames: list, pal: dict, flip: bool = False, outline: bool = True,
           damage: bool = False) -> None:
    """With damage=True the strip holds the normal frames, then the damaged frames."""
    if flip:  # enemies face down (toward the player) at rotation 0
        frames = [list(reversed(f)) for f in frames]
    if damage:
        frames = frames + damaged(frames, len(name))
        pal = {**pal, **DAMAGE_PAL}
    strip([frame_image(f, pal, outline) for f in frames]).save(OUT / f"{name}.png")


# ---------------------------------------------------------------- player
PLAYER_BODY = [
    ".......c.......",
    "......aca......",
    "......aca......",
    ".....aacaa.....",
    ".....abcba.....",
    "..d..abbba..d..",
    "..a.aabbbaa.a..",
    ".aa.aabbbaa.aa.",
    ".aaaaabbbaaaaa.",
    "aaaaaaabaaaaaaa",
    "aab.aaaaaaa.baa",
    "ab..aa...aa..ba",
    "a...aa...aa...a",
]
PLAYER = [
    PLAYER_BODY + [".....f...f.....", ".....e...e.....", "..............."],
    PLAYER_BODY + [".....f...f.....", ".....f...f.....", ".....e...e....."],
]
PLAYER_PAL = {"a": "#f4e3c1", "b": "#3d8bff", "c": "#bff6ff", "d": "#ffb347", "e": "#ffe08a", "f": "#ff7a3d"}

# ---------------------------------------------------------------- enemies (drawn head up, flipped)
BEE = [
    [
        "....a.....a....",
        ".....a...a.....",
        "www..bbbbb..www",
        "wwww.bebeb.wwww",
        "wwwwcccccccwwww",
        ".wwwbbbbbbbwww.",
        "...ccccccccc...",
        "....bbbbbbb....",
        ".....ccccc.....",
        "......b.b......",
    ],
    [
        "....a.....a....",
        ".....a...a.....",
        ".....bbbbb.....",
        ".....bebeb.....",
        ".w..ccccccc..w.",
        "wwwwbbbbbbbwwww",
        "wwwcccccccccwww",
        "wwwwbbbbbbbwwww",
        ".ww..ccccc..ww.",
        "......b.b......",
    ],
]
BEE_PAL = {"a": "#ffd9a8", "b": "#ff7a3d", "c": "#ffb347", "e": "#2a1b4d", "w": "#ffd9a8"}

MOTH = [
    [
        ".a.............a.",
        "..a...........a..",
        "...a..bcccb..a...",
        ".www.bbcccbb.www.",
        "wwwwwbbcccbbwwwww",
        "wwvwbbbcccbbbwvww",
        "wwwwwbbbcbbbwwwww",
        ".wwwbbbbbbbbbwww.",
        "..ww..bbbbb..ww..",
        ".......b.b.......",
    ],
    [
        ".a.............a.",
        "..a...........a..",
        "...a..bcccb..a...",
        "......bcccb......",
        "...wwbbcccbbww...",
        "..wvwbbcccbbwvw..",
        ".wwwwbbbcbbbwwww.",
        ".wwwbbbbbbbbbwww.",
        "..ww..bbbbb..ww..",
        ".......b.b.......",
    ],
]
MOTH_PAL = {"a": "#ffe08a", "b": "#9b5de5", "c": "#ffe08a", "w": "#c9a6ff", "v": "#f4e3c1"}

WARDEN = [
    [
        "..a.............a..",
        "...a...........a...",
        "....a..yyyyy..a....",
        "......bbbbbbb......",
        ".....bbcbbbcbb.....",
        "..ww.bbbbbbbbb.ww..",
        ".wwwbbbdbbbdbbbwww.",
        "wwwwbbbbbbbbbbbwwww",
        "wwwbbbcbbbbbcbbbwww",
        ".ww.bbbbbbbbbbb.ww.",
        "....b..bbbbb..b....",
        "...b....b.b....b...",
    ],
    [
        "..a.............a..",
        "...a...........a...",
        "....a..yyyyy..a....",
        "......bbbbbbb......",
        ".ww..bbcbbbcbb..ww.",
        "wwww.bbbbbbbbb.wwww",
        "wwwwbbbdbbbdbbbwwww",
        ".wwwbbbbbbbbbbbwww.",
        "..wbbbcbbbbbcbbbw..",
        "....bbbbbbbbbbb....",
        "....b..bbbbb..b....",
        "...b....b.b....b...",
    ],
]
WARDEN_PAL = {"a": "#ffe08a", "y": "#ffe08a", "b": "#2bb5a8", "c": "#f4e3c1", "d": "#ffb347", "w": "#ff7a3d"}

FUSEWING = [
    [
        "......a......",
        ".....a.a.....",
        "....bbbbb....",
        "ww.bbcccbb.ww",
        "wwbbcdddcbbww",
        "wwbbcdddcbbww",
        ".wbbbcccbbbw.",
        "...bbbbbbb...",
        "....b...b....",
    ],
    [
        ".....a.a.....",
        "......a......",
        "....bbbbb....",
        "...bbcccbb...",
        "wwbbccdccbbww",
        "wwbbcdddcbbww",
        "wwbbbcccbbbww",
        "...bbbbbbb...",
        "....b...b....",
    ],
]
FUSEWING_PAL = {"a": "#ffe08a", "b": "#73215f", "c": "#fca54d", "d": "#fff4d0", "w": "#cf4b57"}

# ---------------------------------------------------------------- enemies authored facing down
LANCER = [
    [
        "......a......",
        ".....aba.....",
        "..w..bbb..w..",
        "..ww.bcb.ww..",
        ".www.bcb.www.",
        "wwwwbbcbbwwww",
        "www.bbcbb.www",
        "ww..bbcbb..ww",
        "w...bbcbb...w",
        "....bdcdb....",
        ".....bcb.....",
        ".....bcb.....",
        "......c......",
        "......c......",
    ],
    [
        "......a......",
        ".....aba.....",
        "..w..bbb..w..",
        "..ww.bcb.ww..",
        ".www.bcb.www.",
        "wwwwbbcbbwwww",
        "www.bbcbb.www",
        "ww..bbcbb..ww",
        "w...bbcbb...w",
        "....bdcdb....",
        ".....bcb.....",
        ".....bcb.....",
        "......c......",
        "......e......",
    ],
]
LANCER_PAL = {"a": "#ffe08a", "b": "#f4e3c1", "c": "#2bb5a8", "d": "#fca54d", "e": "#ffffff", "w": "#3d8bff"}

SHIELDBEARER = [
    [
        "...a.........a...",
        "....a.......a....",
        ".....bbbbbbb.....",
        "..w.bbcbbbcbb.w..",
        ".wwwbbbbbbbbbwww.",
        "wwwwbbbdbdbbbwwww",
        ".wwwbbbbbbbbbwww.",
        "..w..bbbbbbb..w..",
        "..sssssssssssss..",
        ".sSSSSSSSSSSSSSs.",
        ".ss...........ss.",
    ],
    [
        "...a.........a...",
        "....a.......a....",
        ".....bbbbbbb.....",
        "..w.bbcbbbcbb.w..",
        ".wwwbbbbbbbbbwww.",
        "wwwwbbbdbdbbbwwww",
        ".wwwbbbbbbbbbwww.",
        "..w..bbbbbbb..w..",
        "..sssssssssssss..",
        ".sSSSSSSSSSSsSSs.",
        ".ss...........ss.",
    ],
]
SHIELDBEARER_PAL = {"a": "#ffe08a", "b": "#9aa3c7", "c": "#f4e3c1", "d": "#ffb347", "w": "#5b6390", "s": "#2bb5a8", "S": "#bff6ff"}


def spinner_frames() -> list:
    """Round hull with four spikes; frame 2 is rotated 45 degrees."""
    frames = []
    size, c = 15, 7
    for k in range(2):
        rows = [["." for _ in range(size)] for _ in range(size)]
        for j in range(size):
            for i in range(size):
                d = math.hypot(i - c, j - c)
                if d <= 4.6:
                    rows[j][i] = "b"
                if d <= 2.6:
                    rows[j][i] = "c"
                if d <= 1.0:
                    rows[j][i] = "d"
        for s in range(4):
            a = s * math.pi / 2 + k * math.pi / 4
            for r in (5, 6, 7):
                x, y = round(c + math.cos(a) * r), round(c + math.sin(a) * r)
                if 0 <= x < size and 0 <= y < size:
                    rows[y][x] = "a" if r == 7 else "w"
        frames.append(["".join(r) for r in rows])
    return frames


SPINNER_PAL = {"a": "#ffe08a", "b": "#561b5b", "c": "#2bb5a8", "d": "#fff4d0", "w": "#fca54d"}

# ---------------------------------------------------------------- shots and pickups
# Energy tracer: white-hot head, cyan body, a trail that fades out. No outline: it glows.
PLAYER_BULLET = [
    ["..w..", ".wcw.", ".wcw.", ".cbc.", ".cbc.", "..b..", "..b..", "..t..", "..t..", "..t..", "..d..", "..d..", "..e..", "..e.."],
    ["..w..", ".www.", ".wcw.", ".cbc.", "..b..", "..b..", "..b..", "..t..", "..t..", "..d..", "..d..", "..d..", "..e..", "..e.."],
]
PLAYER_BULLET_PAL = {"w": "#ffffff", "c": "#d8fbff", "b": "#7ef0ff", "t": "#4cc8e8c0", "d": "#3a9fd080", "e": "#3a9fd040"}

# Plasma orb in the reserved red: white-hot core, hot ring, darker rim; core pulses.
ENEMY_BULLET = [
    ["..rrr..", ".rpppr.", "rppwppr", "rpwwwpr", "rppwppr", ".rpppr.", "..rrr.."],
    ["..rrr..", ".rpwpr.", "rpwwwpr", "rwwwwwr", "rpwwwpr", ".rpwpr.", "..rrr.."],
]
ENEMY_BULLET_PAL = {"r": "#b3203c", "p": BULLET_RED, "w": "#fff0f2"}

MUZZLE = [
    ["...w...", "..wcw..", ".wcbcw.", "w.cbc.w", "...b..."],
    [".......", "...w...", "..wcw..", "..cbc..", "...b..."],
]
MUZZLE_PAL = {"w": "#ffffff", "c": "#d8fbff", "b": "#7ef0ff"}


def glow(w: int, h: int) -> Image.Image:
    """Soft white falloff, tinted and added on top of shots in the engine."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            dx, dy = (x + 0.5 - w / 2) / (w / 2), (y + 0.5 - h / 2) / (h / 2)
            a = max(0.0, 1 - math.hypot(dx, dy)) ** 2
            img.putpixel((x, y), (255, 255, 255, round(a * 255)))
    return img


PICKUP = [
    ["..aaa..", ".abbba.", "abbcbba", "abcccba", "abbcbba", ".abbba.", "..aaa.."],
    ["..aaa..", ".abbba.", "abbabba", "abaaaba", "abbabba", ".abbba.", "..aaa.."],
]
PICKUP_PAL = {"a": "#ffe08a", "b": "#2bb5a8", "c": "#ffffff"}


def explosion_frames() -> list:
    """Four frames: hot core, flash ring, breaking ring with sparks, fading embers."""
    rnd = random.Random(7)
    size, c = 21, 10
    stages = [(2.2, 0.0, 0), (4.5, 2.5, 6), (7.0, 5.5, 14), (9.0, 8.0, 18)]
    keys = ["d", "y", "o", "r"]
    frames = []
    for n, (outer, inner, sparks) in enumerate(stages):
        rows = [["." for _ in range(size)] for _ in range(size)]
        for j in range(size):
            for i in range(size):
                d = math.hypot(i - c, j - c)
                if inner <= d <= outer and (n < 2 or rnd.random() < 0.55 - n * 0.1):
                    t = (d - inner) / max(0.01, outer - inner)
                    rows[j][i] = keys[min(3, n + (1 if t > 0.6 else 0))]
        for _ in range(sparks):
            a, r = rnd.uniform(0, math.tau), rnd.uniform(outer * 0.6, outer + 1.5)
            x, y = round(c + math.cos(a) * r), round(c + math.sin(a) * r)
            if 0 <= x < size and 0 <= y < size:
                rows[y][x] = "d" if n < 3 else "y"
        frames.append(["".join(r) for r in rows])
    return frames


EXPLOSION_PAL = {"d": "#fff4d0", "y": "#ffe08a", "o": "#fca54d", "r": "#e86450"}

# ---------------------------------------------------------------- background
SKY_W, SKY_H = 270, 480
# Natural dusk, top to horizon: night blue, slate violet, dusty mauve, rose, peach, warm gold.
SKY_STOPS = [(0.0, "#141a33"), (0.25, "#2b2f55"), (0.5, "#5a4f78"), (0.7, "#9a6f86"),
             (0.86, "#d4937f"), (1.0, "#efbb84")]
SUN_CORE, SUN_EDGE, SUN_GLOW = "#fff3d6", "#ffd9a0", "#f6c08e"


HORIZON = 0.8  # fraction of the height where the sun sets into the cloud sea
CLOUD_SEA = [("#c98f86", "#5b4d6e"), ("#8a6c84", "#463d5c"), ("#655574", "#342e4a"),
             ("#4a4060", "#25223a"), ("#342e4a", "#18162a")]


def mix(a: tuple, b: tuple, t: float) -> tuple:
    return tuple(round(a[k] + (b[k] - a[k]) * t) for k in range(3)) + (255,)


def sky() -> Image.Image:
    """Smooth, undithered dusk gradient above a dark cloud sea. The sea keeps the player's zone
    dark so ships and the reserved bullet color stay readable."""
    img = Image.new("RGBA", (SKY_W, SKY_H))
    hy = round(SKY_H * HORIZON)
    stops = [(t, rgba(c)) for t, c in SKY_STOPS]
    cx, r = SKY_W * 0.68, 40
    core, edge, glow = rgba(SUN_CORE), rgba(SUN_EDGE), rgba(SUN_GLOW)
    for y in range(hy):
        t = y / (hy - 1)
        k = next(i for i in range(len(stops) - 1) if t <= stops[i + 1][0])
        (t0, c0), (t1, c1) = stops[k], stops[k + 1]
        u = (t - t0) / (t1 - t0)
        u = u * u * (3 - 2 * u)  # smoothstep between stops
        row = mix(c0, c1, u)
        for x in range(SKY_W):
            d = math.hypot(x - cx, (y - hy) * 1.0)
            if d <= r:  # sun disc, half set behind the cloud sea
                img.putpixel((x, y), mix(core, edge, (d / r) ** 2))
            else:  # soft glow around the sun
                g = max(0.0, 1 - (d - r) / (r * 2.2)) ** 2 * 0.55
                img.putpixel((x, y), mix(row, glow, g))
    # Cloud sea: rows of puffs, lit rims, darker toward the viewer.
    for y in range(hy, SKY_H):
        for x in range(SKY_W):
            img.putpixel((x, y), rgba(CLOUD_SEA[-1][1]))
    rnd = random.Random(5)
    rows = len(CLOUD_SEA)
    row_h = (SKY_H - hy) / rows
    for k, (rim, body) in enumerate(CLOUD_SEA):
        top = hy + row_h * k - (10 if k == 0 else 2)
        x = rnd.uniform(-20, 0)
        while x < SKY_W + 20:
            rx = rnd.randint(7 + k * 2, 11 + k * 3)
            ry = max(4, int(rx * 0.6))

            def half_width(j: int) -> float:
                return -1.0 if j < -ry else rx * math.sqrt(max(0.0, 1 - (min(j, 0) / ry) ** 2))

            for j in range(-ry, int(row_h) + 16):
                yy = round(top + ry + j)
                if not 0 <= yy < SKY_H:
                    continue
                w = half_width(j)
                for xx in range(round(x - w), round(x + w) + 1):
                    if 0 <= xx < SKY_W:
                        # Rim: within 2px of the puff's upper edge.
                        lit = j < 2 and abs(xx - x) > half_width(j - 2) + 0.5
                        img.putpixel((xx, yy), rgba(rim if lit else body))
            x += rx * rnd.uniform(1.2, 1.7)
    return img


def blob(img: Image.Image, cx: float, cy: float, rx: int, ry: int, col: tuple) -> None:
    """Pixel ellipse with a flat underside, wrapped vertically so the layer tiles."""
    for j in range(-ry, ry // 3 + 1):
        w = int(rx * math.sqrt(max(0.0, 1 - (j / ry) ** 2)))
        y = round(cy + j) % SKY_H
        for x in range(round(cx - w), round(cx + w) + 1):
            if 0 <= x < SKY_W:
                img.putpixel((x, y), col)


def clouds(seed: int, count: int, rim: str, main: str, alpha: int) -> Image.Image:
    """Long, low cloud banks: overlapping flat-bottomed puffs with a lit rim on top."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (SKY_W, SKY_H), (0, 0, 0, 0))
    for k in range(count):
        bx, by = rnd.uniform(-20, SKY_W + 20), (k + rnd.uniform(0.1, 0.7)) * SKY_H / count
        puffs = rnd.randint(4, 7)
        blobs = []
        for m in range(puffs):
            rx = rnd.randint(10, 20)
            ry = max(4, int(rx * rnd.uniform(0.4, 0.6)) - abs(m - puffs // 2))
            blobs.append((bx + (m - puffs / 2) * rx * 1.1, by + rnd.uniform(-2, 2), rx, ry))
        for ox, oy, rx, ry in blobs:
            blob(img, ox, oy - 2, rx, ry, rgba(rim, alpha))
        for ox, oy, rx, ry in blobs:
            blob(img, ox, oy, rx, ry, rgba(main, alpha))
    return img


def main() -> None:
    (OUT / "enemies").mkdir(parents=True, exist_ok=True)
    (OUT / "projectiles").mkdir(exist_ok=True)
    (OUT / "fx").mkdir(exist_ok=True)
    (OUT / "background").mkdir(exist_ok=True)
    sprite("player", PLAYER, PLAYER_PAL)
    sprite("enemies/bee", BEE, BEE_PAL, flip=True)
    sprite("enemies/moth", MOTH, MOTH_PAL, flip=True)
    sprite("enemies/warden", WARDEN, WARDEN_PAL, flip=True, damage=True)
    sprite("enemies/fusewing", FUSEWING, FUSEWING_PAL, flip=True)
    sprite("enemies/lancer", LANCER, LANCER_PAL, damage=True)
    sprite("enemies/spinner", spinner_frames(), SPINNER_PAL, damage=True)
    sprite("enemies/shieldbearer", SHIELDBEARER, SHIELDBEARER_PAL, damage=True)
    sprite("projectiles/player_bullet", PLAYER_BULLET, PLAYER_BULLET_PAL, outline=False)
    sprite("projectiles/enemy_bullet", ENEMY_BULLET, ENEMY_BULLET_PAL, outline=False)
    sprite("projectiles/muzzle_flash", MUZZLE, MUZZLE_PAL, outline=False)
    glow(32, 32).save(OUT / "projectiles" / "glow_round.png")
    sprite("pickup", PICKUP, PICKUP_PAL)
    sprite("fx/explosion", explosion_frames(), EXPLOSION_PAL, outline=False)
    sky().save(OUT / "background" / "sky.png")
    clouds(11, 5, "#8f7591", "#5d5072", 255).save(OUT / "background" / "clouds_far.png")
    clouds(23, 3, "#4a4060", "#2c2842", 235).save(OUT / "background" / "clouds_near.png")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
