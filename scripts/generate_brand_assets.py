"""Derive every WalletMelt logo/icon asset from assets/brand/source/walletmelt_logo_source.webp.

Usage: python scripts/generate_brand_assets.py   (then: dart run flutter_launcher_icons)
Keys the mark off its flat dark background, so holes (clasp ring) become transparent.
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets/brand/source/walletmelt_logo_source.webp")
BG = (14, 13, 20)  # sampled source background, also the launcher background (#0E0D14)


def p(*a):
    return os.path.join(ROOT, *a)


def key_mark():
    src = Image.open(SRC).convert("RGB")
    w, h = src.size
    px = src.load()
    # Per-row foreground colour (the mark is a vertical gradient).
    rows = [None] * h
    for y in range(h):
        pts = [px[x, y] for x in range(w) if max(px[x, y][i] - BG[i] for i in range(3)) > 90]
        if len(pts) > 20:
            rows[y] = tuple(sorted(c[i] for c in pts)[len(pts) // 2] for i in range(3))
    known = [y for y in range(h) if rows[y]]
    for y in range(h):
        if not rows[y]:
            rows[y] = rows[min(known, key=lambda k: abs(k - y))]
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        f = rows[y]
        d = [f[i] - BG[i] for i in range(3)]
        dd = sum(v * v for v in d)
        for x in range(w):
            c = px[x, y]
            a = sum((c[i] - BG[i]) * d[i] for i in range(3)) / dd
            a = 0 if a < 0.04 else min(1.0, (a - 0.04) / 0.96)
            op[x, y] = (f[0], f[1], f[2], round(a * 255))
    return out.crop(out.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox())


def fit(mark, size, frac):
    """Centre mark on a transparent square so its long side is frac of size."""
    s = size * frac / max(mark.size)
    m = mark.resize((round(mark.width * s), round(mark.height * s)), Image.LANCZOS)
    c = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c.alpha_composite(m, ((size - m.width) // 2, (size - m.height) // 2))
    return c


def on_bg(mark, size, frac):
    b = Image.new("RGBA", (size, size), BG + (255,))
    b.alpha_composite(fit(mark, size, frac))
    return b.convert("RGB")


mark = key_mark()
# In-app (transparent)
inapp = fit(mark, 1024, 0.94)
inapp.save(p("assets/brand/optimized/walletmelt_icon_transparent.png"))
inapp.save(p("assets/brand/optimized/walletmelt_main_logo_transparent.png"))
for n in ("walletmelt_icon_transparent.webp", "walletmelt_main_logo_960.webp"):
    inapp.resize((960, 960), Image.LANCZOS).save(p("assets/brand/optimized", n), quality=92, method=6)
# Launcher sources
fit(mark, 1024, 0.5).save(p("assets/brand/generated/walletmelt_app_icon_foreground.png"))
on_bg(mark, 1024, 0.56).save(p("assets/brand/generated/walletmelt_app_icon_launcher.png"))
# Web
for n, s in (("Icon-192", 192), ("Icon-512", 512)):
    on_bg(mark, s, 0.66).save(p("web/icons", n + ".png"))
for n, s in (("Icon-maskable-192", 192), ("Icon-maskable-512", 512)):
    on_bg(mark, s, 0.5).save(p("web/icons", n + ".png"))
on_bg(mark, 64, 0.8).resize((32, 32), Image.LANCZOS).save(p("web/favicon.png"))
# Video
for n in ("walletmelt_icon_transparent.png", "walletmelt_main_logo_transparent.png"):
    inapp.save(p("video/public/branding", n))
print("ok", mark.size)
