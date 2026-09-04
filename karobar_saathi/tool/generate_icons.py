"""
Generate the Karobar Saathi launcher icon set (white microphone on the brand
deep-green gradient) with Pillow.

Produces:
  - Legacy square + round mipmap PNGs (mdpi..xxxhdpi) for android:icon / roundIcon
  - Adaptive-icon foreground (transparent, safe-zone padded) + solid background
  - A 512px Play-style master and an in-app asset used on the language/onboarding UI

Run from the Flutter project root:
    python tool/generate_icons.py
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

# ---------------------------------------------------------------------------
# Brand
# ---------------------------------------------------------------------------
GREEN_TOP = (0, 121, 107)      # #00796B  (a touch lighter for the gradient top)
GREEN_BOTTOM = (0, 77, 64)     # #004D40
WHITE = (255, 255, 255, 255)

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES_DIR = os.path.join(PROJECT_ROOT, "android", "app", "src", "main", "res")
ASSET_DIR = os.path.join(PROJECT_ROOT, "assets", "branding")

# Legacy launcher densities (px) for the square/round icons.
LEGACY_DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Adaptive icon layers are authored at 108dp; foreground art must sit inside the
# central 72dp safe zone. We render each density's foreground/background.
ADAPTIVE_DENSITIES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}


def _vertical_gradient(size: int) -> Image.Image:
    """A top-to-bottom brand-green gradient square."""
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / max(size - 1, 1)
        r = round(GREEN_TOP[0] + (GREEN_BOTTOM[0] - GREEN_TOP[0]) * t)
        g = round(GREEN_TOP[1] + (GREEN_BOTTOM[1] - GREEN_TOP[1]) * t)
        b = round(GREEN_TOP[2] + (GREEN_BOTTOM[2] - GREEN_TOP[2]) * t)
        grad.putpixel((0, y), (r, g, b))
    return grad.resize((size, size))


def _draw_mic(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float,
              color=WHITE) -> None:
    """Draw a rounded microphone centred on (cx, cy).

    `scale` is the mic capsule width in px; the rest is derived from it so the
    glyph is proportional at every density.
    """
    capsule_w = scale
    capsule_h = scale * 1.5
    top = cy - capsule_h * 0.62
    left = cx - capsule_w / 2
    right = cx + capsule_w / 2
    bottom = top + capsule_h
    radius = capsule_w / 2

    # Mic capsule (rounded rectangle).
    draw.rounded_rectangle(
        [left, top, right, bottom],
        radius=radius,
        fill=color,
    )

    # The U-shaped stand cradle, drawn as a thick arc.
    stroke = max(2, round(scale * 0.16))
    cradle_r = capsule_w * 0.95
    arc_box = [cx - cradle_r, cy - cradle_r * 0.65,
               cx + cradle_r, cy + cradle_r * 1.05]
    draw.arc(arc_box, start=20, end=160, fill=color, width=stroke)

    # Stem down to the base.
    stem_top = cy + cradle_r * 1.02
    stem_bottom = stem_top + scale * 0.55
    draw.line([(cx, stem_top), (cx, stem_bottom)], fill=color, width=stroke)

    # Base foot.
    foot_w = capsule_w * 0.9
    draw.line(
        [(cx - foot_w / 2, stem_bottom), (cx + foot_w / 2, stem_bottom)],
        fill=color,
        width=stroke,
    )


def _rounded_mask(size: int, radius_ratio: float = 0.22) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    r = round(size * radius_ratio)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=255)
    return mask


def _circle_mask(size: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([0, 0, size - 1, size - 1], fill=255)
    return mask


def make_legacy_icon(size: int, round_icon: bool) -> Image.Image:
    """Full-bleed gradient tile + mic, clipped to a squircle or circle."""
    base = _vertical_gradient(size).convert("RGBA")
    draw = ImageDraw.Draw(base)
    _draw_mic(draw, cx=size / 2, cy=size * 0.47, scale=size * 0.30)

    mask = _circle_mask(size) if round_icon else _rounded_mask(size)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out


def make_adaptive_foreground(size: int) -> Image.Image:
    """Transparent foreground; mic sized to sit inside the 72/108 safe zone."""
    fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(fg)
    # Safe zone is the central 2/3; keep the mic comfortably inside it.
    _draw_mic(draw, cx=size / 2, cy=size * 0.46, scale=size * 0.22)
    return fg


def make_adaptive_background(size: int) -> Image.Image:
    return _vertical_gradient(size).convert("RGBA")


def make_master(size: int = 512) -> Image.Image:
    return make_legacy_icon(size, round_icon=False)


def _save(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"  wrote {os.path.relpath(path, PROJECT_ROOT)}")


def main() -> None:
    print("Generating legacy launcher icons…")
    for folder, size in LEGACY_DENSITIES.items():
        _save(make_legacy_icon(size, round_icon=False),
              os.path.join(RES_DIR, folder, "ic_launcher.png"))
        _save(make_legacy_icon(size, round_icon=True),
              os.path.join(RES_DIR, folder, "ic_launcher_round.png"))

    print("Generating adaptive icon layers…")
    for folder, size in ADAPTIVE_DENSITIES.items():
        _save(make_adaptive_foreground(size),
              os.path.join(RES_DIR, folder, "ic_launcher_foreground.png"))
        _save(make_adaptive_background(size),
              os.path.join(RES_DIR, folder, "ic_launcher_background.png"))

    print("Generating in-app + master assets…")
    _save(make_master(512), os.path.join(ASSET_DIR, "app_icon_512.png"))
    _save(make_legacy_icon(256, round_icon=False),
          os.path.join(ASSET_DIR, "app_icon.png"))

    print("Done.")


if __name__ == "__main__":
    main()
