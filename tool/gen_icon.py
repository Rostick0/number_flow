"""Draws the Number Flow launcher icon (original artwork) into Android mipmaps.

Usage: python3 tool/gen_icon.py android/app/src/main/res
"""
import sys
from PIL import Image, ImageDraw, ImageFont

RES = sys.argv[1]
SIZES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
BG = (91, 108, 255)
TILES = [((127, 209, 199), '2'), ((93, 184, 232), '4'), ((242, 179, 61), '8')]


def font(px):
    for path in ['/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf',
                 '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
                 '/Library/Fonts/Arial Bold.ttf']:
        try:
            return ImageFont.truetype(path, px)
        except OSError:
            pass
    return ImageFont.load_default()


def draw(size):
    s = size * 4  # supersample
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * 0.22, fill=BG)
    tile = s * 0.3
    # Three tiles stepping down diagonally: the "flow".
    for i, (color, label) in enumerate(TILES):
        x = s * 0.12 + i * s * 0.255
        y = s * 0.18 + i * s * 0.2
        edge = tuple(int(c * 0.8) for c in color)
        d.rounded_rectangle([x, y + s * 0.025, x + tile, y + tile + s * 0.025], radius=tile * 0.24, fill=edge)
        d.rounded_rectangle([x, y, x + tile, y + tile], radius=tile * 0.24, fill=color)
        f = font(int(tile * 0.62))
        bbox = d.textbbox((0, 0), label, font=f)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text((x + (tile - tw) / 2 - bbox[0], y + (tile - th) / 2 - bbox[1]), label,
               font=f, fill=(255, 255, 255))
    return img.resize((size, size), Image.LANCZOS)


for density, px in SIZES.items():
    draw(px).save(f'{RES}/mipmap-{density}/ic_launcher.png')
