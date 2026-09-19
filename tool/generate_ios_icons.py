#!/usr/bin/env python3
"""Regenerates ios/Runner/Assets.xcassets/AppIcon.appiconset from the brand logo.

The iOS set shipped as the Flutter placeholder. Apple rejects that (4.3), and
App Store icons must be opaque — an alpha channel is rejected outright — so the
logo is flattened onto white and re-centred to fill the tile.
"""
import json, pathlib
from PIL import Image, ImageChops

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets/images/app_launcher_icon.png'
OUT = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
FILL = 0.86  # share of the tile the artwork spans; iOS masks the corners itself

src = Image.open(SRC).convert('RGBA')
flat = Image.new('RGB', src.size, 'white')
flat.paste(src, mask=src.split()[3])

# Crop the baked-in white margin so the logo is centred on its own ink, not on
# whatever padding the source file happened to carry.
bg = Image.new('RGB', flat.size, 'white')
box = ImageChops.difference(flat, bg).convert('L').point(lambda p: 255 if p > 10 else 0).getbbox()
logo = flat.crop(box)

def tile(px):
    span = int(px * FILL)
    w, h = logo.size
    s = span / max(w, h)
    art = logo.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    canvas = Image.new('RGB', (px, px), 'white')
    canvas.paste(art, ((px - art.width) // 2, (px - art.height) // 2))
    return canvas

contents = json.loads((OUT / 'Contents.json').read_text())
for entry in contents['images']:
    if 'filename' not in entry:
        continue
    side, scale = float(entry['size'].split('x')[0]), int(entry['scale'].rstrip('x'))
    px = round(side * scale)
    tile(px).save(OUT / entry['filename'], 'PNG')
    print(f"{entry['filename']:34} {px}x{px}")
