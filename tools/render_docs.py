# Renders the README pictures (terminal mock-up + palette strip) in the paper palette.
# usage: python tools/render_docs.py <JetBrainsMono dir> <out dir>
import os
import sys
from PIL import Image, ImageDraw, ImageFont

FONTS, OUT = sys.argv[1], sys.argv[2]
reg = ImageFont.truetype(os.path.join(FONTS, "JetBrainsMono-Regular.ttf"), 26)
bold = ImageFont.truetype(os.path.join(FONTS, "JetBrainsMono-Bold.ttf"), 26)

BG, FG = "#fcfcfa", "#2f2f2f"
PAL = {
    "fg": FG, "dim": "#8c8c88", "blue": "#5b6fa8", "red": "#b5584e", "green": "#5e8a5c",
    "yellow": "#a5803a", "magenta": "#8d6597", "cyan": "#4d8a8c", "rule": "#dcdcd8",
}

# each line: list of (text, color, bold)
def L(*parts):
    return [(p, "fg", False) if isinstance(p, str) else p for p in parts]

d, b, bl, r = "dim", "fg", "blue", "red"
art = open(os.path.join(os.path.dirname(__file__), "..", "art", "cat.txt"), encoding="utf-8").read().rstrip("\n").split("\n")
aw = max(map(len, art)) + 2
info = [
    [("19 ноября, четверг · 09:41", b, True)],
    [("up 2d 4h 12m · mem 2310M / 7728M", d, False)],
    [],
    [("▶ ревью пулреквестов · 25м", bl, False)],
    [("сегодня:", bl, False)],
    [("· ", d, False), ("14:00 созвон по релизу", "fg", False)],
    [("· ", d, False), ("дописать README", "fg", False)],
]
lines = []
for i in range(max(len(art), len(info))):
    a = art[i] if i < len(art) else ""
    lines.append([(a.ljust(aw), d, False)] + (info[i] if i < len(info) else []))
lines += [
    [],
    L("~ $ ", ("t", "fg", True)),
    [("сегодня", b, True), (" чт 19.11 · открыто 3 из 4 · 1ч 5м в работе", d, False)],
    [(" 1  ", d, False), ("[/]", bl, False), (" ревью пулреквестов", "fg", False), (" ▶ 25м", bl, False)],
    [(" 2  ", d, False), ("[ ] ", "fg", False), ("14:00", bl, False), (" созвон по релизу", "fg", False)],
    [(" 3  ", d, False), ("[ ] ", "fg", False), ("дописать README", "fg", True), (" ↑", r, True)],
    [(" 4  [x] разобрать почту", d, False), (" · 40м", d, False)],
    [],
    L("~ $ ", ("t done ревью", "fg", False)),
    [("готово", "green", False), (" ревью пулреквестов", "fg", False), (" · за 25м", d, False)],
    [],
    L("~ $ ", ("t report", "fg", False)),
    [("   40м  ", "fg", False), ("█" * 12 + " " * 8, d, False), ("  разобрать почту", "fg", False)],
    [("   25м  ", "fg", False), ("█" * 8 + " " * 12, d, False), ("  ревью пулреквестов", "fg", False)],
    [(" 1ч 5м  ", "fg", True), ("всего", d, False)],
    [],
    L("~ $ ", ("█", "dim", False)),
]

cw, ch, padx, pady, bar = reg.getlength("M"), 40, 44, 30, 56
cols = 74
W = int(padx * 2 + cw * cols)
H = int(bar + pady * 2 + ch * len(lines))
img = Image.new("RGB", (W, H), BG)
dr = ImageDraw.Draw(img)
# tmux tab bar
dr.text((padx, 14), " 1 ~ ", font=bold, fill=FG)
dr.text((padx + cw * 6, 14), " 2 paper  3 notes", font=reg, fill=PAL["dim"])
st = "▶ ревью пулреквестов 25м"
dr.text((W - padx - cw * (len(st) + 6), 14), st, font=reg, fill=PAL["blue"])
dr.text((W - padx - cw * 4, 14), "main", font=reg, fill=PAL["dim"])
dr.line((0, bar - 6, W, bar - 6), fill=PAL["rule"], width=2)
y = bar + pady
for line in lines:
    x = padx
    for text, color, isb in line:
        f = bold if isb else reg
        dr.text((x, y), text, font=f, fill=PAL.get(color, color))
        x += f.getlength(text)
    y += ch
img.save(os.path.join(OUT, "terminal.png"), optimize=True)

# palette strip
names = [("bg", BG), ("fg", FG), ("dim", PAL["dim"]), ("blue", PAL["blue"]), ("red", PAL["red"]),
         ("green", PAL["green"]), ("yellow", PAL["yellow"]), ("magenta", PAL["magenta"]), ("cyan", PAL["cyan"])]
sw, sh = 150, 150
p = Image.new("RGB", (sw * len(names), sh + 70), BG)
pd = ImageDraw.Draw(p)
small = ImageFont.truetype(os.path.join(FONTS, "JetBrainsMono-Regular.ttf"), 20)
for i, (n, c) in enumerate(names):
    x = i * sw
    pd.rectangle((x + 10, 10, x + sw - 10, sh - 10), fill=c, outline=PAL["rule"], width=2)
    pd.text((x + 14, sh + 4), n, font=small, fill=FG)
    pd.text((x + 14, sh + 32), c, font=small, fill=PAL["dim"])
p.save(os.path.join(OUT, "palette.png"), optimize=True)
print("ok", W, H)
