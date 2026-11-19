# Photo -> ASCII wallpaper on light paper. Thin strokes use direction chars (/ \ | -), solid areas use density chars.
# usage: ascii_photo.py IN.jpg OUT.png W H FONTSIZE FONT.ttf [SIDEBAR_PX] [CROP_Y_FRAC]
import math, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

src, out, W, H, FS, FONT = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), sys.argv[6]
SIDEBAR = int(sys.argv[7]) if len(sys.argv) > 7 else 0
CY = float(sys.argv[8]) if len(sys.argv) > 8 else 0.5

im = ImageOps.grayscale(Image.open(src))
# cover-crop to W x H (art area excludes the sidebar)
AW = W - SIDEBAR
s = max(AW / im.width, H / im.height)
im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
x0 = (im.width - AW) // 2
y0 = int((im.height - H) * CY)
im = im.crop((x0, y0, x0 + AW, y0 + H))
im = ImageOps.autocontrast(im, cutoff=1)

ink = 1 - np.asarray(im, np.float32) / 255          # 0 paper .. 1 black
font = ImageFont.truetype(FONT, FS)
cw = font.getlength("M"); ch = int(FS * 1.25)
cols, rows = int(AW / cw), int(H / ch)

# per-cell coverage + gradient direction (Sobel on a slightly blurred map)
cell = np.asarray(Image.fromarray((ink * 255).astype(np.uint8)).resize((cols, rows), Image.BOX), np.float32) / 255
blur = np.asarray(Image.fromarray((ink * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(cw * 0.6)), np.float32) / 255
gy, gx = np.gradient(blur)
gx = np.asarray(Image.fromarray(gx.astype(np.float32), mode="F").resize((cols, rows), Image.BOX))
gy = np.asarray(Image.fromarray(gy.astype(np.float32), mode="F").resize((cols, rows), Image.BOX))
mag = np.hypot(gx, gy)
mag_n = mag / (np.percentile(mag, 99) + 1e-6)

DENSE = " .:-=+*#%@"
def dir_char(gx, gy):
    # stroke runs perpendicular to the gradient
    a = (math.degrees(math.atan2(-gy, gx)) + 90) % 180
    if a < 22.5 or a >= 157.5: return "-"
    if a < 67.5: return "/"
    if a < 112.5: return "|"
    return "\\"

# typographic fill for solid areas: Poe, "The Raven" (1845, public domain)
POEM = ("Once upon a midnight dreary, while I pondered, weak and weary, over many a quaint and curious "
        "volume of forgotten lore, while I nodded, nearly napping, suddenly there came a tapping, as of "
        "some one gently rapping, rapping at my chamber door. Quoth the Raven, Nevermore. ")
TEXT = POEM.replace(" ", "")
rng = np.random.default_rng(13)
tone_noise = np.asarray(Image.fromarray((rng.random((rows // 3 + 2, cols // 3 + 2)) * 255).astype(np.uint8))
                        .resize((cols, rows), Image.BICUBIC), np.float32) / 255
BG = (244, 244, 241)
img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
ox = SIDEBAR + (AW - cols * cw) / 2
k = 0
LIGHT = " .,:;-~=+"
DEEP = "@#%&$#@%"
DARK = "#%*+=*#+"
grain = rng.random((rows, cols))
for r in range(rows):
    for c in range(cols):
        v = float(cell[r, c])
        if v < 0.08:
            continue
        t = tone_noise[r, c]
        if v < 0.62 and mag_n[r, c] > 0.35:          # thin branch / edge: stroke direction
            chr_ = dir_char(gx[r, c], gy[r, c])
            g = int(115 - 85 * min(1, v * 1.6))
        elif v >= 0.55:                              # solid: textured symbols, picked by a smooth noise field
            pool = DEEP if v > 0.8 else DARK
            j = int((t * 0.85 + 0.15 * float(grain[r, c])) * len(pool)) % len(pool)
            chr_ = pool[j]
            g = int(14 + 52 * t * (1.12 - v))
        else:                                        # half-tones: light texture
            chr_ = LIGHT[min(len(LIGHT) - 1, int(v / 0.55 * len(LIGHT)))]
            g = int(150 - 80 * v)
        if chr_ == " ":
            continue
        d.text((ox + c * cw, r * ch), chr_, font=font, fill=(g, g, g))

if SIDEBAR:
    small = ImageFont.truetype(FONT, int(FS * 1.4))
    d.rectangle((0, 0, SIDEBAR, H), fill=(30, 30, 28))
    d.line((SIDEBAR, 0, SIDEBAR, H), fill=(205, 205, 200), width=2)
img.save(out, optimize=True)
print("ok", cols, "x", rows)
