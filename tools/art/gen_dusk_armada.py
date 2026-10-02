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
    h = hex_color.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


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


def sprite(name: str, frames: list, pal: dict, flip: bool = False, outline: bool = True) -> None:
    if flip:  # enemies face down (toward the player) at rotation 0
        frames = [list(reversed(f)) for f in frames]
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

BUTTERFLY = [
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
BUTTERFLY_PAL = {"a": "#ffe08a", "b": "#9b5de5", "c": "#ffe08a", "w": "#c9a6ff", "v": "#f4e3c1"}

BOSS = [
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
BOSS_PAL = {"a": "#ffe08a", "y": "#ffe08a", "b": "#2bb5a8", "c": "#f4e3c1", "d": "#ffb347", "w": "#ff7a3d"}

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
PLAYER_BULLET = [["ww", "ww", "bb", "bb", "bb", "bb", "bb", "bb"]]
PLAYER_BULLET_PAL = {"w": "#ffffff", "b": "#7ef0ff"}

ENEMY_BULLET = [[".rrr.", "rryrr", "ryyyr", "rryrr", ".rrr."]]
ENEMY_BULLET_PAL = {"r": BULLET_RED, "y": "#ffe08a"}

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
SKY_BANDS = ["#140a28", "#1e0f38", "#2c1247", "#3f1653", "#561b5b", "#73215f",
             "#932b60", "#b2385d", "#cf4b57", "#e86450", "#f5834a", "#fca54d"]
SUN = ["#ffe58a", "#ffc56e", "#ff9f62", "#ff7a59", "#ff7a59"]


HORIZON = 0.8  # fraction of the height where the sun sets into the cloud sea
CLOUD_SEA = [("#932b60", "#561b5b"), ("#73215f", "#3f1653"), ("#561b5b", "#2c1247"),
             ("#3f1653", "#1e0f38"), ("#2c1247", "#140a28")]


def sky() -> Image.Image:
    """Banded, dithered sunset above a dark cloud sea. The sea keeps the player's zone
    dark so ships and the reserved bullet color stay readable."""
    img = Image.new("RGBA", (SKY_W, SKY_H))
    hy = round(SKY_H * HORIZON)
    band_h = hy / len(SKY_BANDS)
    for y in range(hy):
        f = y / band_h
        i = min(len(SKY_BANDS) - 1, int(f))
        fr = f - i
        for x in range(SKY_W):
            col = SKY_BANDS[i]
            # Two-step dither into the next band (checker, then 3/4 fill).
            if i < len(SKY_BANDS) - 1 and fr > 0.6 and ((x + y) % 2 == 0 or fr > 0.8 and x % 2 == 0):
                col = SKY_BANDS[i + 1]
            img.putpixel((x, y), rgba(col))
    cx, r = round(SKY_W * 0.68), 44
    for j in range(-r, 1):
        y = hy + j
        # Retro sun: slices widen toward the horizon.
        if j > -22 and (y % 6) < 1 + (j + 22) / 9:
            continue
        w = int(math.sqrt(r * r - j * j))
        col = SUN[min(3, int((j + r) / r * 4))]
        for x in range(cx - w, cx + w + 1):
            if 0 <= x < SKY_W:
                img.putpixel((x, y), rgba(col))
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
    sprite("enemies/butterfly", BUTTERFLY, BUTTERFLY_PAL, flip=True)
    sprite("enemies/boss", BOSS, BOSS_PAL, flip=True)
    sprite("enemies/fusewing", FUSEWING, FUSEWING_PAL, flip=True)
    sprite("enemies/lancer", LANCER, LANCER_PAL)
    sprite("enemies/spinner", spinner_frames(), SPINNER_PAL)
    sprite("enemies/shieldbearer", SHIELDBEARER, SHIELDBEARER_PAL)
    sprite("projectiles/player_bullet", PLAYER_BULLET, PLAYER_BULLET_PAL)
    sprite("projectiles/enemy_bullet", ENEMY_BULLET, ENEMY_BULLET_PAL)
    sprite("pickup", PICKUP, PICKUP_PAL)
    sprite("fx/explosion", explosion_frames(), EXPLOSION_PAL, outline=False)
    sky().save(OUT / "background" / "sky.png")
    clouds(11, 5, "#7a3070", "#4f1c5c", 255).save(OUT / "background" / "clouds_far.png")
    clouds(23, 3, "#43205c", "#22103a", 235).save(OUT / "background" / "clouds_near.png")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
