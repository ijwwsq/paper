# Taskbar icons in the paper style: white rounded card + graphite glyph.
# Glyphs: Simple Icons SVGs (CC0, https://simpleicons.org) or built-in paths below.
# usage: python tools/taskbar_icons.py <svg dir> <out dir> name=slug-or-builtin [name=... ...]
import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

BUILTIN = {  # 24x24, nonzero fill; holes run the other way
    "folder": "M2 6a2 2 0 0 1 2-2h5l2 2h9a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2z",
    "monitor": "M3 4h18a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1h-7v2h3v2H7v-2h3v-2H3a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1zm1 2v9h16V6z",
    "calendar": "M4 5h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2zM4 10v9h16v-9zM7 2h2v4H7zM15 2h2v4h-2z",
    "notepad": "M6 2h9l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zM6 4v16h12V8h-4V4zM8 11h8v1.6H8zM8 14.2h8v1.6H8zM8 17.4h5v1.6H8z",
}
def _rgb(name, default):
    v = os.environ.get(name, default).lstrip("#")
    return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
# colors: PAPER_ICON_INK / _CARD / _EDGE (hex); defaults = paper light
INK, CARD, EDGE = _rgb("PAPER_ICON_INK", "2f2f2f"), _rgb("PAPER_ICON_CARD", "ffffff"), _rgb("PAPER_ICON_EDGE", "c8c8c4")


# ── SVG path → list of polylines (subpaths) ──────────────────────────────
def tokens(d):
    for m in re.finditer(r"[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?", d):
        yield m.group(0)


def arc_points(x0, y0, rx, ry, phi, large, sweep, x, y, n=24):
    if rx == 0 or ry == 0:
        return [(x, y)]
    phi = math.radians(phi)
    cp, sp = math.cos(phi), math.sin(phi)
    dx, dy = (x0 - x) / 2, (y0 - y) / 2
    x1, y1 = cp * dx + sp * dy, -sp * dx + cp * dy
    rx, ry = abs(rx), abs(ry)
    lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
    if lam > 1:
        rx, ry = rx * math.sqrt(lam), ry * math.sqrt(lam)
    num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    den = rx * rx * y1 * y1 + ry * ry * x1 * x1
    co = math.sqrt(max(0, num / den)) * (-1 if large == sweep else 1)
    cx1, cy1 = co * rx * y1 / ry, -co * ry * x1 / rx
    cx, cy = cp * cx1 - sp * cy1 + (x0 + x) / 2, sp * cx1 + cp * cy1 + (y0 + y) / 2
    ang = lambda ux, uy, vx, vy: math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    t1 = ang(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
    dt = ang((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
    if not sweep and dt > 0:
        dt -= 2 * math.pi
    elif sweep and dt < 0:
        dt += 2 * math.pi
    pts = []
    for k in range(1, n + 1):
        t = t1 + dt * k / n
        pts.append((cp * rx * math.cos(t) - sp * ry * math.sin(t) + cx, sp * rx * math.cos(t) + cp * ry * math.sin(t) + cy))
    return pts


def parse(d):
    tk = list(tokens(d))
    i, cmd = 0, None
    x = y = sx = sy = 0.0
    lc = None  # last control point for S/T
    subs, cur = [], []

    def num():
        nonlocal i
        v = float(tk[i]); i += 1
        return v

    def flag():  # arc flags may be glued to what follows: "a2 2 0 012-2" → 0, 1, 2
        nonlocal i
        t = tk[i].lstrip("+")
        if len(t) > 1 and t[0] in "01":
            tk[i] = t[1:]
            return int(t[0])
        i += 1
        return int(float(t))

    def bez(p0, p1, p2, p3, n=16):
        return [((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0],
                 (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1])
                for t in (k / n for k in range(1, n + 1))]

    while i < len(tk):
        if re.fullmatch(r"[A-Za-z]", tk[i]):
            cmd = tk[i]; i += 1
            if cmd in "Zz":
                if cur:
                    subs.append(cur)
                cur, x, y, lc = [], sx, sy, None
                continue
        rel = cmd.islower()
        C = cmd.upper()
        ox, oy = (x, y) if rel else (0, 0)
        if C == "M":
            if cur:
                subs.append(cur)
            x, y = num() + ox, num() + oy
            sx, sy, cur, lc = x, y, [(x, y)], None
            cmd = "l" if rel else "L"
        elif C == "L":
            x, y = num() + ox, num() + oy; cur.append((x, y)); lc = None
        elif C == "H":
            x = num() + (x if rel else 0); cur.append((x, y)); lc = None
        elif C == "V":
            y = num() + (y if rel else 0); cur.append((x, y)); lc = None
        elif C == "C":
            p1 = (num() + ox, num() + oy); p2 = (num() + ox, num() + oy); p3 = (num() + ox, num() + oy)
            cur += bez((x, y), p1, p2, p3); x, y = p3; lc = p2
        elif C == "S":
            p1 = (2 * x - lc[0], 2 * y - lc[1]) if lc else (x, y)
            p2 = (num() + ox, num() + oy); p3 = (num() + ox, num() + oy)
            cur += bez((x, y), p1, p2, p3); x, y = p3; lc = p2
        elif C in "QT":
            if C == "Q":
                q = (num() + ox, num() + oy)
            else:
                q = (2 * x - lc[0], 2 * y - lc[1]) if lc else (x, y)
            p3 = (num() + ox, num() + oy)
            p1 = (x + 2 / 3 * (q[0] - x), y + 2 / 3 * (q[1] - y)); p2 = (p3[0] + 2 / 3 * (q[0] - p3[0]), p3[1] + 2 / 3 * (q[1] - p3[1]))
            cur += bez((x, y), p1, p2, p3); x, y = p3; lc = q
        elif C == "A":
            rx, ry, ph = num(), num(), num()
            la, sw = flag(), flag()
            ex, ey = num() + ox, num() + oy
            cur += arc_points(x, y, rx, ry, ph, la, sw, ex, ey); x, y = ex, ey; lc = None
        else:
            raise ValueError(f"unsupported path command {cmd}")
    if cur:
        subs.append(cur)
    return subs


def rasterize(subs, size):
    """nonzero winding fill on a size×size grid of a 24×24 viewBox"""
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float64)
    px, py = (xs + 0.5) * 24 / size, (ys + 0.5) * 24 / size
    wind = np.zeros((size, size), np.int32)
    for sub in subs:
        pts = sub + [sub[0]]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            if y0 == y1:
                continue
            left = (x1 - x0) * (py - y0) - (px - x0) * (y1 - y0)
            if y0 < y1:
                wind += ((py >= y0) & (py < y1) & (left > 0)).astype(np.int32)
            else:
                wind -= ((py >= y1) & (py < y0) & (left < 0)).astype(np.int32)
    return wind != 0


def glyph(name, svgdir, size=512):
    if name in BUILTIN:
        d = BUILTIN[name]
    else:
        d = re.search(r'<path[^>]*\sd="([^"]+)"', open(os.path.join(svgdir, f"{name}.svg"), encoding="utf-8").read()).group(1)
    mask = rasterize(parse(d), size)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.putalpha(Image.fromarray((mask * 255).astype(np.uint8)))
    ink = Image.new("RGBA", (size, size), INK)
    ink.putalpha(img.getchannel("A"))
    return ink


def card(g, label=None):
    S = 256
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((16, 16, 240, 240), 40, fill=CARD, outline=EDGE, width=5)
    gs = g.resize((136, 136), Image.LANCZOS)
    im.alpha_composite(gs, (60, 60))
    if label:  # small text inside a built-in glyph (e.g. "N" in the calendar)
        f = ImageFont.truetype(os.environ.get("PAPER_FONT_BOLD", "C:/Windows/Fonts/consolab.ttf"), 46)
        w = d.textlength(label, font=f)
        d.text((128 - w / 2, 150), label, font=f, fill=INK, anchor="lm")
    return im


if __name__ == "__main__":
    svgdir, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    for spec in sys.argv[3:]:
        name, src = spec.split("=", 1)
        label = None
        if ":" in src:
            src, label = src.split(":", 1)
        im = card(glyph(src, svgdir), label)
        im.save(os.path.join(out, f"{name}.png"))
        im.save(os.path.join(out, f"{name}.ico"), sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
        print("ok", name)
