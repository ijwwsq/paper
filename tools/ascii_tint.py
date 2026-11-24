# Re-tint a light ASCII-photo render (tools/ascii_photo.py) into gruvbox dark:
# paper background → #282828, ink → gray #928374 → cream #ebdbb2 by darkness.
# usage: python tools/ascii_tint.py IN.png OUT.png [SIDEBAR_PX]
#   SIDEBAR_PX — optional dark #1d2021 strip on the left (under a vertical taskbar)
import sys

import numpy as np
from PIL import Image, ImageDraw

src, out = sys.argv[1], sys.argv[2]
sidebar = int(sys.argv[3]) if len(sys.argv) > 3 else 0
im = np.asarray(Image.open(src).convert("RGB"), np.float32)
L = im.mean(axis=2)
bgL = 243.0                                   # paper background (244,244,241)
k = np.clip((bgL - L) / (bgL - 15), 0, 1)     # 0 = paper, 1 = darkest ink
k = k ** 0.8                                  # lift mid-tones a little
bg = np.array([40, 40, 40], np.float32)       # #282828
mid = np.array([146, 131, 116], np.float32)   # #928374 for faint strokes
cream = np.array([235, 219, 178], np.float32) # #ebdbb2 for dense ink
col = np.where(k[..., None] < 0.5,
               bg + (mid - bg) * (k[..., None] / 0.5),
               mid + (cream - mid) * ((k[..., None] - 0.5) / 0.5))
img = Image.fromarray(col.clip(0, 255).astype(np.uint8))
if sidebar:
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, sidebar, img.height), fill=(29, 32, 33))       # #1d2021
    d.line((sidebar, 0, sidebar, img.height), fill=(60, 56, 54), width=1)
img.save(out, optimize=True)
print("ok", out, img.size)
