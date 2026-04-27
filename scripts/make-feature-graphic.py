#!/usr/bin/env python3
"""Generate a 1024x500 feature graphic for Play Store from the Sanad logo."""
from PIL import Image, ImageDraw
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGO = os.path.join(BASE, 'assets/images/logo_transparent_high_quality.png')
OUT = os.path.join(BASE, 'play-store-assets/feature-graphic-1024x500.png')

# Sanad primary teal (from app_colors.dart likely)
TEAL = (28, 100, 115)        # deep teal
TEAL_DARK = (15, 70, 82)     # darker for gradient

canvas = Image.new('RGB', (1024, 500), TEAL)
draw = ImageDraw.Draw(canvas)

# Vertical-ish gradient: darker at bottom-left
for y in range(500):
    for x in range(1024):
        # distance from bottom-left corner (0, 499)
        dx = x / 1024
        dy = (499 - y) / 500
        t = (dx * 0.4 + (1 - dy) * 0.6)
        r = int(TEAL[0] * (1 - t) + TEAL_DARK[0] * t * 0.6)
        g = int(TEAL[1] * (1 - t) + TEAL_DARK[1] * t * 0.6)
        b = int(TEAL[2] * (1 - t) + TEAL_DARK[2] * t * 0.6)
        # too slow for per-pixel — use vertical bands instead

# Simpler: horizontal gradient via paste
for x in range(1024):
    t = x / 1024
    r = int(TEAL[0] * (1 - t * 0.3) + TEAL_DARK[0] * t * 0.3)
    g = int(TEAL[1] * (1 - t * 0.3) + TEAL_DARK[1] * t * 0.3)
    b = int(TEAL[2] * (1 - t * 0.3) + TEAL_DARK[2] * t * 0.3)
    draw.line([(x, 0), (x, 500)], fill=(r, g, b))

# Place logo centered, scaled to ~380px tall
logo = Image.open(LOGO).convert('RGBA')
scale = 380 / logo.height
logo = logo.resize((int(logo.width * scale), 380), Image.LANCZOS)
x = (1024 - logo.width) // 2
y = (500 - logo.height) // 2
canvas.paste(logo, (x, y), logo)

canvas.save(OUT, 'PNG', optimize=True)
print(f'Wrote {OUT} ({canvas.size})')
