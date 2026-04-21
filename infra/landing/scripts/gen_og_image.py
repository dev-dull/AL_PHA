"""Generate the planyr.day LinkedIn preview image."""
from io import BytesIO
import requests
from PIL import Image, ImageDraw, ImageFont

# LinkedIn recommended: 1200x627 (1.91:1)
W, H = 1200, 627

# Bullet-journal palette (same as the site)
PAPER = (245, 240, 232)   # #F5F0E8
PAPER_DIM = (237, 231, 218)  # #EDE7DA
INK = (44, 37, 32)         # #2C2520
INK_SOFT = (107, 101, 96)  # #6B6560
ACCENT = (91, 138, 114)    # #5B8A72
DOT = (213, 204, 188)      # #D5CCBC

# Marker colors (light theme)
M_DOT = (26, 58, 92)       # navy
M_SLASH = (43, 94, 158)    # blue
M_X = (45, 90, 61)         # green
M_EVENT = (92, 58, 110)    # purple


def get_font(size: int, variant: str = "regular") -> ImageFont.FreeTypeFont:
    # Download Patrick Hand TTF once per run
    url = "https://github.com/google/fonts/raw/main/ofl/patrickhand/PatrickHand-Regular.ttf"
    if not hasattr(get_font, "_bytes"):
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        get_font._bytes = r.content
    return ImageFont.truetype(BytesIO(get_font._bytes), size)


def draw_dot_grid(draw: ImageDraw.ImageDraw):
    step = 28
    for y in range(0, H, step):
        for x in range(0, W, step):
            draw.ellipse([x - 1, y - 1, x + 1, y + 1], fill=DOT)


def draw_text(draw: ImageDraw.ImageDraw, xy, text, font, fill):
    draw.text(xy, text, font=font, fill=fill)


def text_width(draw: ImageDraw.ImageDraw, text: str, font) -> int:
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def draw_pill(draw: ImageDraw.ImageDraw, xy, text, font, fill_bg, fill_text, pad=(20, 10)):
    tw = text_width(draw, text, font)
    _, _, _, th_bottom = draw.textbbox((0, 0), text, font=font)
    ascent, descent = font.getmetrics()
    th = ascent + descent
    x, y = xy
    rect = [x, y, x + tw + pad[0] * 2, y + th + pad[1] * 2]
    draw.rounded_rectangle(rect, radius=(rect[3] - rect[1]) // 2, fill=fill_bg)
    draw.text((x + pad[0], y + pad[1]), text, font=font, fill=fill_text)
    return rect


def draw_marker(draw: ImageDraw.ImageDraw, kind: str, color, cx: int, cy: int, size: int, slash_font):
    """Draw one Alastair-method marker, centered at (cx, cy)."""
    r = size // 2
    if kind == "dot":
        draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=color)
    elif kind == "event":
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=4)
    elif kind == "check":
        pts = [(cx - r + 4, cy + 2), (cx - 4, cy + r - 6), (cx + r - 2, cy - r + 4)]
        draw.line(pts, fill=color, width=6, joint="curve")
    elif kind == "slash":
        # slash uses the font so it looks handwritten
        tw = text_width(draw, "/", slash_font)
        ascent, _ = slash_font.getmetrics()
        draw.text((cx - tw // 2, cy - ascent // 2 - 4), "/", font=slash_font, fill=color)


def draw_grid(draw: ImageDraw.ImageDraw, origin, cell=72):
    """Draw a 7-column weekly grid with markers."""
    ox, oy = origin
    days = ["M", "T", "W", "T", "F", "S", "S"]
    header_font = get_font(24)
    slash_font = get_font(54)

    # Column headers
    for i, d in enumerate(days):
        cx = ox + i * cell + cell // 2
        tw = text_width(draw, d, header_font)
        draw.text((cx - tw // 2, oy), d, font=header_font, fill=INK_SOFT)

    # Dashed separator under headers
    sep_y = oy + 40
    for x in range(ox, ox + cell * 7, 10):
        draw.line([(x, sep_y), (x + 5, sep_y)], fill=INK_SOFT, width=1)

    # Markers: dot, slash, check, dot, event, empty, empty
    row = [
        ("dot", M_DOT),
        ("slash", M_SLASH),
        ("check", M_X),
        ("dot", M_DOT),
        ("event", M_EVENT),
        (None, None),
        (None, None),
    ]
    cell_y = sep_y + 10
    for i, (kind, color) in enumerate(row):
        if kind is None:
            continue
        cx = ox + i * cell + cell // 2
        cy = cell_y + cell // 2
        draw_marker(draw, kind, color, cx, cy, size=40, slash_font=slash_font)


def main():
    img = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(img)

    draw_dot_grid(draw)

    # Left column: title + tagline + badge
    title_font = get_font(180)
    tagline_font = get_font(38)
    badge_font = get_font(28)

    left_x = 80
    draw.text((left_x, 110), "planyr", font=title_font, fill=INK)

    tagline = "a weekly planner"
    draw.text((left_x + 6, 390), tagline, font=tagline_font, fill=INK_SOFT)

    draw_pill(draw, (left_x + 6, 475), "coming soon", badge_font,
              PAPER_DIM, INK_SOFT, pad=(24, 12))

    # Right column: weekly grid teaser
    draw_grid(draw, origin=(660, 220), cell=72)

    # Subtle accent line
    draw.line([(660, 200), (660 + 72 * 7, 200)], fill=ACCENT, width=3)

    # Domain footer
    footer_font = get_font(26)
    footer = "planyr.day"
    tw = text_width(draw, footer, footer_font)
    draw.text((W - tw - 60, H - 50), footer, font=footer_font, fill=INK_SOFT)

    out = "/Users/alastairdrong/wip/AlPHA/infra/landing/og-image.png"
    img.save(out, "PNG", optimize=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
