"""Generate the planyr app icon in all common sizes.

Concept: a bold lowercase "p" rendered in Patrick Hand on cream paper,
with a subtle dot-grid texture. Scales from 1024×1024 master down to
16×16 favicon via Lanczos resampling.

Outputs (saved relative to the script location):
  planyr-icon-{size}.png                  — combined (bg + mark)
  planyr-icon-foreground-{size}.png       — mark only (transparent bg)
  planyr-icon-background-{size}.png       — bg only (no mark)
  planyr-icon-dark-{size}.png             — dark variant combined

Run:
  python3 -m venv /tmp/oggen  # if not already present
  /tmp/oggen/bin/pip install pillow requests
  /tmp/oggen/bin/python assets/branding/gen_logo.py
"""
from io import BytesIO
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFont

# ── Palette (mirrors docs/design/tokens.md) ─────────────────────────
PAPER = (245, 240, 232)          # #F5F0E8
INK = (44, 37, 32)               # #2C2520
ACCENT = (91, 138, 114)          # #5B8A72
DOT_GRID_LIGHT = (213, 204, 188) # #D5CCBC
PAPER_DARK = (44, 42, 38)        # #2C2A26
INK_DARK = (232, 224, 212)       # #E8E0D4
DOT_GRID_DARK = (74, 69, 61)     # #4A453D

OUT_DIR = Path(__file__).parent

# Sizes needed across iOS, Android, macOS, web. Ordered largest-first
# so logging reads nicely.
SIZES = [1024, 512, 256, 192, 180, 167, 152, 144, 128, 120,
         108, 96, 87, 80, 76, 72, 64, 60, 58, 48, 40, 32, 29, 20, 16]

# Sizes where we also emit a transparent-bg foreground variant (for
# Android adaptive icons and dark-mode compositing).
FG_SIZES = [1024, 512, 432, 256, 192, 108]


def get_font(size: int) -> ImageFont.FreeTypeFont:
    """Download Patrick Hand once, return sized FreeType font."""
    url = ("https://github.com/google/fonts/raw/main/ofl/"
           "patrickhand/PatrickHand-Regular.ttf")
    if not hasattr(get_font, "_bytes"):
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        get_font._bytes = r.content
    return ImageFont.truetype(BytesIO(get_font._bytes), size)


def draw_background(size: int, bg_color, dot_color):
    """Cream (or dark) background with a faint dot-grid texture."""
    img = Image.new("RGBA", (size, size), bg_color + (255,))
    draw = ImageDraw.Draw(img)

    # Dot grid — scale step with image size; faint.
    step = max(12, size // 24)
    radius = max(1, size // 512)
    # Render the grid at ~30% opacity so it reads as texture only.
    dotted = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ddraw = ImageDraw.Draw(dotted)
    for y in range(step, size, step):
        for x in range(step, size, step):
            ddraw.ellipse(
                [x - radius, y - radius, x + radius, y + radius],
                fill=dot_color + (80,),
            )
    img.alpha_composite(dotted)
    return img, draw


def draw_mark(img: Image.Image, size: int, ink_color,
              accent_color=ACCENT, show_dot: bool = True,
              scale: float = 0.78):
    """Draw lowercase 'p' centered, with an accent-color dot marker
    to its right at the x-height — echoing the product's marker
    vocabulary ('p •'). [scale] controls how much of the canvas the
    mark occupies (lower for adaptive-icon safe zones)."""
    draw = ImageDraw.Draw(img)
    font_size = int(size * scale)
    font = get_font(font_size)

    glyph = "p"
    bbox = draw.textbbox((0, 0), glyph, font=font)
    gx, gy, gx2, gy2 = bbox
    gw, gh = gx2 - gx, gy2 - gy

    # Horizontal: center the *group* (p + dot gap + dot) on the canvas.
    dot_r = int(size * 0.06)
    gap = int(size * 0.05)
    group_w = gw + (gap + dot_r * 2 if show_dot else 0)
    x = (size - group_w) // 2 - gx
    y = (size - gh) // 2 - gy - int(size * 0.02)

    draw.text((x, y), glyph, font=font, fill=ink_color)

    if show_dot:
        # Place the dot at the baseline of the "p" bowl (i.e. where
        # a period would naturally sit next to the letter). The "p"
        # has a descender; the baseline is roughly 60% down its glyph
        # bbox for Patrick Hand.
        baseline_y = y + gy + int(gh * 0.60)
        dx = x + gx + gw + gap + dot_r
        dy = baseline_y - dot_r
        draw.ellipse(
            [dx - dot_r, dy - dot_r, dx + dot_r, dy + dot_r],
            fill=accent_color,
        )


def render_variant(size: int, *, bg, ink, dot,
                   transparent_bg: bool = False,
                   scale: float = 0.78) -> Image.Image:
    """Compose bg (optional) + mark into a single RGBA image."""
    if transparent_bg:
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    else:
        img, _ = draw_background(size, bg, dot)
    draw_mark(img, size, ink, scale=scale)
    return img


def render_macos_variant(size: int, *, bg, ink, dot) -> Image.Image:
    """macOS-style icon: rounded-rect body inset from the canvas with
    transparent margin, per Apple's app icon template.

    For a 1024 canvas: 100px inset, 824×824 body, 185px corner radius.
    The mark is drawn smaller (scale 0.55) so it has the generous
    padding conventional for macOS icons.
    """
    # Inset and corner radius scale linearly with canvas size so the
    # proportions match Apple's template at any output size.
    inset = int(size * 100 / 1024)
    body = size - 2 * inset
    corner_r = int(body * 185 / 824)

    # Render a full-canvas background + mark, then mask with the
    # rounded-rect body so everything outside becomes transparent.
    full = render_variant(size, bg=bg, ink=ink, dot=dot, scale=0.55)

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [inset, inset, size - inset, size - inset],
        radius=corner_r, fill=255,
    )

    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(full, (0, 0), mask)
    return out


def main():
    # Master renders at 1024 for best quality; downsample for the rest
    # so antialiasing is consistent.
    light_master = render_variant(1024, bg=PAPER, ink=INK,
                                  dot=DOT_GRID_LIGHT)
    dark_master = render_variant(1024, bg=PAPER_DARK, ink=INK_DARK,
                                 dot=DOT_GRID_DARK)
    light_bg_only, _ = draw_background(1024, PAPER, DOT_GRID_LIGHT)
    light_fg_master = render_variant(1024, bg=PAPER, ink=INK,
                                     dot=DOT_GRID_LIGHT,
                                     transparent_bg=True)

    # Combined sizes
    for s in SIZES:
        combined = light_master.resize((s, s), Image.Resampling.LANCZOS)
        combined.convert("RGB").save(OUT_DIR / f"planyr-icon-{s}.png",
                                     optimize=True)

    # Dark-mode combined (fewer sizes — used on dark surfaces only)
    for s in [1024, 512, 256, 192, 108]:
        combined = dark_master.resize((s, s), Image.Resampling.LANCZOS)
        combined.convert("RGB").save(
            OUT_DIR / f"planyr-icon-dark-{s}.png", optimize=True,
        )

    # Foreground-only (transparent bg) for Android adaptive icons
    for s in FG_SIZES:
        fg = light_fg_master.resize((s, s), Image.Resampling.LANCZOS)
        fg.save(OUT_DIR / f"planyr-icon-foreground-{s}.png",
                optimize=True)

    # Adaptive-icon foreground: same mark at smaller scale (~52%) so
    # it stays inside Android's 66% safe zone after the circular or
    # squircle mask is applied.
    adaptive_fg = render_variant(1024, bg=PAPER, ink=INK,
                                 dot=DOT_GRID_LIGHT,
                                 transparent_bg=True, scale=0.52)
    for s in [1024, 432, 192, 108]:
        fg = adaptive_fg.resize((s, s), Image.Resampling.LANCZOS)
        fg.save(OUT_DIR / f"planyr-icon-adaptive-foreground-{s}.png",
                optimize=True)

    # macOS variant: rounded-rect body with transparent margin.
    macos_master = render_macos_variant(1024, bg=PAPER, ink=INK,
                                        dot=DOT_GRID_LIGHT)
    for s in [1024, 512, 256, 128, 64, 32, 16]:
        mac = macos_master.resize((s, s), Image.Resampling.LANCZOS)
        mac.save(OUT_DIR / f"planyr-icon-macos-{s}.png", optimize=True)

    # Background-only for Android adaptive icons
    for s in [1024, 432, 108]:
        bg, _ = draw_background(s, PAPER, DOT_GRID_LIGHT)
        bg.convert("RGB").save(
            OUT_DIR / f"planyr-icon-background-{s}.png", optimize=True,
        )

    print(f"wrote {len(SIZES) + 5 + len(FG_SIZES) + 3} icon files "
          f"to {OUT_DIR}")


if __name__ == "__main__":
    main()
