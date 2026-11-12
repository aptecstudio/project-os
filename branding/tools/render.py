#!/usr/bin/env python3
"""Generate the project-os branding images from their sources (D-023).

Usage:    python3 branding/tools/render.py
Requires: rsvg-convert, Python 3 with Pillow and NumPy; the Inter font for the preview.

Produces:
  branding/logo/project-os-logo-{256,96}.png
  branding/logo/project-os-logo-dark-256.png   (dark variant, for light backgrounds)
  branding/grub-theme/{logo,background}.png
  branding/grub-theme/select_{nw,n,ne,w,c,e,sw,s,se}.png
  branding/grub-theme/terminal_box_{nw,n,ne,w,c,e,sw,s,se}.png
  branding/previews/grub-menu.png   (approximate preview, not installed)
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

BRANDING_DIR = Path(__file__).resolve().parents[1]
LOGO_SVG = BRANDING_DIR / "logo" / "project-os-logo.svg"
THEME_DIR = BRANDING_DIR / "grub-theme"
PREVIEWS_DIR = BRANDING_DIR / "previews"

# Boot palette (MEMORY.md §3)
BACKGROUND_COLOR = (0x0B, 0x0D, 0x12)
GLOW_COLOR = (0x2A, 0x2F, 0x6B)
TEXT_COLOR = (0xF2, 0xF4, 0xF8)
ITEM_COLOR = (0x9A, 0xA3, 0xB2)
MUTED_COLOR = (0x7D, 0x85, 0x97)
FAINT_COLOR = (0x59, 0x61, 0x73)

SCREEN_SIZE = (1920, 1080)
INTER_FONT_DIR = Path("/usr/share/fonts/opentype/inter")

# 4x4 Bayer matrix for ordered dithering
BAYER_MATRIX = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

# Boxes are drawn at this scale and then reduced, for smooth (antialiased) edges
SUPERSAMPLING = 4


def render_svg(svg: Path, output: Path, size_px: int) -> None:
    """Render an SVG file to a square PNG of the given size with rsvg-convert."""
    subprocess.run(
        [
            "rsvg-convert",
            "-w",
            str(size_px),
            "-h",
            str(size_px),
            "-o",
            str(output),
            str(svg),
        ],
        check=True,
    )


def background() -> Image.Image:
    """Draw the dark background with a soft glow above the center, behind the logo."""
    width, height = SCREEN_SIZE
    y, x = np.mgrid[0:height, 0:width].astype(np.float32)
    center_x, center_y = width / 2, height * 0.30
    distance = np.sqrt(
        ((x - center_x) / (width * 0.55)) ** 2 + ((y - center_y) / (height * 0.60)) ** 2
    )
    # 1 at the center of the glow, 0 at its edges
    intensity = np.clip(1.0 - distance, 0.0, 1.0) ** 2.2
    base = np.array(BACKGROUND_COLOR, np.float32)
    glow = np.array(GLOW_COLOR, np.float32)
    pixels = base + (glow - base) * intensity[..., None] * 0.55
    # Ordered dithering (instead of random noise): avoids color banding and compresses
    # well, so the PNG stays light to load in GRUB
    dither = (np.array(BAYER_MATRIX, np.float32) + 0.5) / 16.0 - 0.5
    pixels += np.tile(dither, (height // 4 + 1, width // 4 + 1))[:height, :width, None]
    return Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGB")


def nine_slice(prefix: str, radius: int, fill: tuple, border: tuple | None) -> None:
    """Write the 9 pieces of a rounded box, as GRUB's pixmap styles expect them."""
    size = radius * 2 + 1
    scaled = size * SUPERSAMPLING
    large_box = Image.new("RGBA", (scaled, scaled), (0, 0, 0, 0))
    ImageDraw.Draw(large_box).rounded_rectangle(
        (0, 0, scaled - 1, scaled - 1),
        radius=radius * SUPERSAMPLING,
        fill=fill,
        outline=border,
        width=SUPERSAMPLING if border else 0,
    )
    box = large_box.resize((size, size), Image.LANCZOS)

    # Corners, edges and center, as (left, top, right, bottom)
    pieces = {
        "nw": (0, 0, radius, radius),
        "n": (radius, 0, radius + 1, radius),
        "ne": (radius + 1, 0, size, radius),
        "w": (0, radius, radius, radius + 1),
        "c": (radius, radius, radius + 1, radius + 1),
        "e": (radius + 1, radius, size, radius + 1),
        "sw": (0, radius + 1, radius, size),
        "s": (radius, radius + 1, radius + 1, size),
        "se": (radius + 1, radius + 1, size, size),
    }
    for name, area in pieces.items():
        box.crop(area).save(THEME_DIR / f"{prefix}_{name}.png")


def font(style: str, size: int) -> ImageFont.FreeTypeFont:
    """Load the Inter font in the given style (Regular, Medium, SemiBold…) and size."""
    return ImageFont.truetype(str(INTER_FONT_DIR / f"Inter-{style}.otf"), size)


def preview(background_image: Image.Image) -> Image.Image:
    """Draw an approximate preview of the menu: real GRUB may differ by a few pixels."""
    image = background_image.convert("RGBA")
    width, height = SCREEN_SIZE
    draw = ImageDraw.Draw(image)

    logo_top = int(height * 0.20)
    logo = Image.open(THEME_DIR / "logo.png").convert("RGBA")
    image.alpha_composite(logo, (width // 2 - 48, logo_top))

    draw.text(
        (width / 2, logo_top + 116 + 18),
        "project-os",
        font=font("SemiBold", 28),
        fill=TEXT_COLOR,
        anchor="mm",
    )

    entries = [
        "project-os",
        "project-os (previous version)",
        "Windows Boot Manager",
        "UEFI Firmware Settings",
    ]
    # Same geometry as boot_menu in theme.txt
    menu_left = width // 2 - 260
    menu_top = logo_top + 180
    menu_width = 520
    item_height = 44
    item_spacing = 6
    item_padding = 16

    selection = Image.new("RGBA", (menu_width, item_height), (0, 0, 0, 0))
    ImageDraw.Draw(selection).rounded_rectangle(
        (0, 0, menu_width - 1, item_height - 1),
        radius=10,
        fill=(255, 255, 255, 26),
        outline=(255, 255, 255, 46),
        width=1,
    )
    for index, label in enumerate(entries):
        item_top = menu_top + index * (item_height + item_spacing)
        text_position = (menu_left + item_padding, item_top + item_height / 2)
        if index == 0:
            image.alpha_composite(selection, (menu_left, item_top))
            draw.text(
                text_position,
                label,
                font=font("Medium", 18),
                fill=(255, 255, 255),
                anchor="lm",
            )
        else:
            draw.text(
                text_position,
                label,
                font=font("Regular", 18),
                fill=ITEM_COLOR,
                anchor="lm",
            )

    draw.text(
        (width / 2, height - 96 + 12),
        "Booting automatically in 5 seconds",
        font=font("Regular", 14),
        fill=MUTED_COLOR,
        anchor="mm",
    )
    draw.text(
        (width / 2, height - 64 + 12),
        "↑ ↓ to select  ·  Enter to boot  ·  E to edit  ·  C for a command line",
        font=font("Regular", 14),
        fill=FAINT_COLOR,
        anchor="mm",
    )
    return image.convert("RGB")


def main() -> None:
    """Render every branding image."""
    PREVIEWS_DIR.mkdir(exist_ok=True)
    for size_px in (256, 96):
        output = BRANDING_DIR / "logo" / f"project-os-logo-{size_px}.png"
        render_svg(LOGO_SVG, output, size_px)

    # Dark variant of the same placeholder, for light backgrounds (e.g. README on
    # GitHub)
    dark_svg = PREVIEWS_DIR / "logo-dark.svg"
    dark_svg.write_text(LOGO_SVG.read_text().replace("#FFFFFF", "#0B0D12"))
    render_svg(dark_svg, BRANDING_DIR / "logo" / "project-os-logo-dark-256.png", 256)
    dark_svg.unlink()
    render_svg(LOGO_SVG, THEME_DIR / "logo.png", 96)

    background_image = background()
    background_image.save(THEME_DIR / "background.png", optimize=True)

    nine_slice("select", 10, (255, 255, 255, 26), (255, 255, 255, 46))
    nine_slice("terminal_box", 12, (16, 19, 27, 235), (255, 255, 255, 30))

    preview(background_image).save(PREVIEWS_DIR / "grub-menu.png", optimize=True)
    print("ok")


if __name__ == "__main__":
    main()
