"""Generates Lumen's app icon, adaptive icon layers, TV banner and splash
images for Android and iOS from one design (Inter ExtraBold wordmark on the
app's dark background with the sign-in screen's red glow).

Run from the project root:  python tool/branding/generate_icons.py
Requires Pillow.
"""
import json
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Inter-ExtraBold.ttf')
BG = (12, 12, 16)          # #0C0C10 (theme background)
ACCENT = (255, 51, 71)     # #FF3347 (dark-theme accent)
WORD = 'Lumen'

RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
IOS = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets')
OUT = os.path.join(ROOT, 'assets', 'branding')


def glow_background(size, strength=1.0):
    """Dark square with a soft red glow top-left, like the sign-in screen."""
    img = Image.new('RGB', (size, size), BG)
    glow = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(glow)
    r = int(size * 0.62)
    cx, cy = int(size * 0.18), int(size * 0.12)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=int(150 * strength))
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.18))
    red = Image.new('RGB', (size, size), (120, 18, 32))
    return Image.composite(red, img, glow)


def wordmark(width_px, color=ACCENT, underline=True):
    """Transparent image of the 'Lumen' wordmark exactly [width_px] wide."""
    probe = ImageFont.truetype(FONT, 400)
    box = probe.getbbox(WORD)
    scale = width_px / (box[2] - box[0])
    font = ImageFont.truetype(FONT, max(8, int(400 * scale)))
    box = font.getbbox(WORD)
    w, h = box[2] - box[0], box[3] - box[1]
    bar_h = max(2, int(h * 0.12)) if underline else 0
    gap = int(h * 0.22) if underline else 0
    img = Image.new('RGBA', (w, h + gap + bar_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.text((-box[0], -box[1]), WORD, font=font, fill=color + (255,))
    if underline:
        # A short accent bar under the "L": a lit strip, like a screen edge.
        bw = int(w * 0.34)
        d.rounded_rectangle([0, h + gap, bw, h + gap + bar_h], radius=bar_h // 2, fill=color + (255,))
    return img


def paste_center(base, overlay, dy=0):
    x = (base.width - overlay.width) // 2
    y = (base.height - overlay.height) // 2 + dy
    base.paste(overlay, (x, y), overlay)
    return base


def master_icon(size):
    """Full-bleed square icon: glow background + wordmark at ~70 % width."""
    img = glow_background(size).convert('RGBA')
    return paste_center(img, wordmark(int(size * 0.70)))


def rounded(img, radius_frac=0.22):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=int(img.width * radius_frac), fill=255)
    out = img.copy()
    out.putalpha(mask)
    return out


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def android():
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, f in densities.items():
        # Legacy launcher icon (pre-Android 8): rounded square, 48 dp.
        s = int(48 * f)
        save(rounded(master_icon(s * 4).resize((s, s), Image.LANCZOS)), os.path.join(RES, f'mipmap-{name}', 'ic_launcher.png'))
        # Adaptive layers are 108 dp; the visible safe zone is the middle 66 dp.
        a = int(108 * f)
        save(glow_background(a * 2).resize((a, a), Image.LANCZOS), os.path.join(RES, f'mipmap-{name}', 'ic_launcher_background.png'))
        fg = Image.new('RGBA', (a * 4, a * 4), (0, 0, 0, 0))
        paste_center(fg, wordmark(int(a * 4 * 0.50)))
        save(fg.resize((a, a), Image.LANCZOS), os.path.join(RES, f'mipmap-{name}', 'ic_launcher_foreground.png'))
        mono = Image.new('RGBA', (a * 4, a * 4), (0, 0, 0, 0))
        paste_center(mono, wordmark(int(a * 4 * 0.50), color=(255, 255, 255)))
        save(mono.resize((a, a), Image.LANCZOS), os.path.join(RES, f'mipmap-{name}', 'ic_launcher_monochrome.png'))
        # Android 12+ splash icon: 288 dp canvas, content inside a 192 dp circle.
        sp = int(288 * f)
        splash = Image.new('RGBA', (sp * 2, sp * 2), (0, 0, 0, 0))
        paste_center(splash, wordmark(int(sp * 2 * 0.52)))
        save(splash.resize((sp, sp), Image.LANCZOS), os.path.join(RES, f'drawable-{name}', 'splash_icon.png'))
        # Pre-12 splash: wordmark bitmap, 180 dp wide.
        lw = int(180 * f)
        save(wordmark(lw), os.path.join(RES, f'drawable-{name}', 'splash_logo.png'))

    os.makedirs(os.path.join(RES, 'mipmap-anydpi-v26'), exist_ok=True)
    with open(os.path.join(RES, 'mipmap-anydpi-v26', 'ic_launcher.xml'), 'w', encoding='utf-8') as fh:
        fh.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
            '</adaptive-icon>\n'
        )

    # Android TV banner, 320x180 (xhdpi = 2x of 160x90 dp).
    banner = Image.new('RGBA', (640, 360), BG + (255,))
    g = glow_background(640).crop((0, 0, 640, 360)).convert('RGBA')
    banner.paste(g, (0, 0))
    paste_center(banner, wordmark(380))
    save(banner.resize((320, 180), Image.LANCZOS).convert('RGB'), os.path.join(RES, 'drawable-xhdpi', 'tv_banner.png'))


def ios():
    d = os.path.join(IOS, 'AppIcon.appiconset')
    with open(os.path.join(d, 'Contents.json'), encoding='utf-8') as fh:
        contents = json.load(fh)
    big = master_icon(2048)
    for img in contents['images']:
        name = img.get('filename')
        if not name:
            continue
        pts = float(img['size'].split('x')[0])
        px = int(round(pts * float(img['scale'].rstrip('x'))))
        # iOS icons must be opaque and square; the system rounds the corners.
        save(big.resize((px, px), Image.LANCZOS).convert('RGB'), os.path.join(d, name))

    li = os.path.join(IOS, 'LaunchImage.imageset')
    for suffix, f in (('', 1), ('@2x', 2), ('@3x', 3)):
        save(wordmark(int(180 * f)), os.path.join(li, f'LaunchImage{suffix}.png'))


def masters():
    save(master_icon(1024).convert('RGB'), os.path.join(OUT, 'icon_1024.png'))
    save(wordmark(800), os.path.join(OUT, 'wordmark.png'))


if __name__ == '__main__':
    masters()
    android()
    ios()
    print('Icons, banner and splash images generated.')
