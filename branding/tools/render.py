#!/usr/bin/env python3
"""Genera le immagini del branding di project-os a partire dai sorgenti.

Uso:  python3 branding/tools/render.py
Richiede: rsvg-convert, Python 3 con Pillow e NumPy; per l'anteprima il font Inter.

Produce:
  branding/logo/project-os-logo-{256,96}.png
  branding/logo/project-os-logo-dark-256.png   (variante scura, per sfondi chiari)
  branding/grub-theme/{logo,background}.png
  branding/grub-theme/select_{nw,n,ne,w,c,e,sw,s,se}.png
  branding/grub-theme/terminal_box_{nw,n,ne,w,c,e,sw,s,se}.png
  branding/previews/grub-menu.png   (anteprima approssimata, non installata)
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LOGO_SVG = ROOT / "logo" / "project-os-logo.svg"
THEME = ROOT / "grub-theme"
PREVIEWS = ROOT / "previews"

# Palette di avvio (MEMORY.md §3)
BG = (0x0B, 0x0D, 0x12)
GLOW = (0x2A, 0x2F, 0x6B)
TEXT = (0xF2, 0xF4, 0xF8)
ITEM = (0x9A, 0xA3, 0xB2)
MUTED = (0x7D, 0x85, 0x97)
FAINT = (0x59, 0x61, 0x73)

SIZE = (1920, 1080)
INTER = Path("/usr/share/fonts/opentype/inter")


def render_svg(svg: Path, out: Path, px: int) -> None:
    subprocess.run(
        ["rsvg-convert", "-w", str(px), "-h", str(px), "-o", str(out), str(svg)],
        check=True,
    )


def background() -> Image.Image:
    """Fondo scuro con un alone morbido sopra il centro, dove sta il logo."""
    w, h = SIZE
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = w / 2, h * 0.30
    d = np.sqrt(((x - cx) / (w * 0.55)) ** 2 + ((y - cy) / (h * 0.60)) ** 2)
    t = np.clip(1.0 - d, 0.0, 1.0) ** 2.2  # 1 al centro, 0 ai bordi
    bg = np.array(BG, np.float32)
    glow = np.array(GLOW, np.float32)
    img = bg + (glow - bg) * t[..., None] * 0.55
    # Retinatura ordinata 4x4 (al posto del rumore casuale): evita le bande di colore
    # e si comprime bene, così il PNG resta leggero da caricare in GRUB
    bayer = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]],
                      np.float32) + 0.5) / 16.0 - 0.5
    img += np.tile(bayer, (h // 4 + 1, w // 4 + 1))[:h, :w, None]
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")


def nine_slice(prefix: str, radius: int, fill: tuple, border: tuple | None) -> None:
    """Scrive i 9 pezzi di un riquadro arrotondato, come li vuole GRUB."""
    s = radius * 2 + 1
    big = Image.new("RGBA", (s * 4, s * 4), (0, 0, 0, 0))  # disegno a 4x per l'antialias
    d = ImageDraw.Draw(big)
    d.rounded_rectangle(
        (0, 0, s * 4 - 1, s * 4 - 1),
        radius=radius * 4,
        fill=fill,
        outline=border,
        width=4 if border else 0,
    )
    box = big.resize((s, s), Image.LANCZOS)
    r = radius
    parts = {
        "nw": (0, 0, r, r), "n": (r, 0, r + 1, r), "ne": (r + 1, 0, s, r),
        "w": (0, r, r, r + 1), "c": (r, r, r + 1, r + 1), "e": (r + 1, r, s, r + 1),
        "sw": (0, r + 1, r, s), "s": (r, r + 1, r + 1, s), "se": (r + 1, r + 1, s, s),
    }
    for name, crop in parts.items():
        box.crop(crop).save(THEME / f"{prefix}_{name}.png")


def font(style: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(INTER / f"Inter-{style}.otf"), size)


def preview(bg: Image.Image) -> Image.Image:
    """Anteprima approssimata del menu con PIL: GRUB vero può differire di qualche pixel."""
    img = bg.convert("RGBA")
    w, h = SIZE
    d = ImageDraw.Draw(img)

    logo_top = int(h * 0.20)
    logo = Image.open(THEME / "logo.png").convert("RGBA")
    img.alpha_composite(logo, (w // 2 - 48, logo_top))

    d.text((w / 2, logo_top + 116 + 18), "project-os", font=font("SemiBold", 28),
           fill=TEXT, anchor="mm")

    entries = [
        "project-os",
        "project-os (versione precedente)",
        "Windows Boot Manager",
        "Impostazioni firmware UEFI",
    ]
    left, top, width, ih, gap, pad = w // 2 - 260, logo_top + 180, 520, 44, 6, 16
    sel = Image.new("RGBA", (width, ih), (0, 0, 0, 0))
    ImageDraw.Draw(sel).rounded_rectangle(
        (0, 0, width - 1, ih - 1), radius=10,
        fill=(255, 255, 255, 26), outline=(255, 255, 255, 46), width=1,
    )
    for i, label in enumerate(entries):
        y = top + i * (ih + gap)
        if i == 0:
            img.alpha_composite(sel, (left, y))
            d.text((left + pad, y + ih / 2), label, font=font("Medium", 18),
                   fill=(255, 255, 255), anchor="lm")
        else:
            d.text((left + pad, y + ih / 2), label, font=font("Regular", 18),
                   fill=ITEM, anchor="lm")

    d.text((w / 2, h - 96 + 12), "Avvio automatico tra 5 secondi",
           font=font("Regular", 14), fill=MUTED, anchor="mm")
    d.text((w / 2, h - 64 + 12),
           "↑ ↓ per scegliere  ·  Invio per avviare  ·  E per modificare  ·  "
           "C per la riga di comando",
           font=font("Regular", 14), fill=FAINT, anchor="mm")
    return img.convert("RGB")


def main() -> None:
    PREVIEWS.mkdir(exist_ok=True)
    for px in (256, 96):
        render_svg(LOGO_SVG, ROOT / "logo" / f"project-os-logo-{px}.png", px)
    # Variante scura dello stesso segnaposto, per sfondi chiari (es. README su GitHub)
    dark_svg = PREVIEWS / "logo-dark.svg"
    dark_svg.write_text(LOGO_SVG.read_text().replace("#FFFFFF", "#0B0D12"))
    render_svg(dark_svg, ROOT / "logo" / "project-os-logo-dark-256.png", 256)
    dark_svg.unlink()
    render_svg(LOGO_SVG, THEME / "logo.png", 96)

    bg = background()
    bg.save(THEME / "background.png", optimize=True)

    nine_slice("select", 10, (255, 255, 255, 26), (255, 255, 255, 46))
    nine_slice("terminal_box", 12, (16, 19, 27, 235), (255, 255, 255, 30))

    preview(bg).save(PREVIEWS / "grub-menu.png", optimize=True)
    print("ok")


if __name__ == "__main__":
    main()
