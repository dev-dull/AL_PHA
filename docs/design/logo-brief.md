# Logo & app icon brief — planyr

Designer brief for a logo / app icon. Can be handed to a human designer,
pasted into an AI image tool, or used as the start of a design sprint.

## What is planyr

A weekly planner app. Users see their whole week at a glance, mark each
day with a simple symbol, and migrate what they don't finish to the next
week. The aesthetic is **handwritten on cream paper** — a warm, analog
counterpoint to the glossy productivity-app norm.

## What this icon is for

- Primary: home-screen icon on iOS and Android
- Also: App Store / Play Store hero, macOS dock icon, browser favicon
- Must be recognizable at 60×60 pt (iOS home), 48×48 dp (Android), and
  still legible at 16×16 (favicon)

## Design language

One metaphor — a handwritten planner on cream paper. Every decision
reinforces that feeling.

**Palette** (use only these; avoid saturated primaries):

| Role | Hex | Notes |
|------|-----|-------|
| Paper | `#F5F0E8` | warm cream, the canvas |
| Ink | `#2C2520` | dark brown-grey, the primary stroke color |
| Accent (sparingly) | `#5B8A72` | muted teal — a washi-tape highlight |
| Dark paper (for dark variant) | `#2C2A26` | warm dark grey, not pure black |

**Feel:**
- Handwritten, not geometric — slight irregularity in strokes
- Muted, not saturated — fountain pen on paper, not screen RGB
- Warm, not cool — no pure white, no pure black, no saturated blues

**Typography (if used in the mark):** Patrick Hand (Google Fonts).

**Product motif:** the app uses a six-symbol marker vocabulary —
`•  /  ✓  >  <  ○`. The dot (`•`) is the most fundamental; the open
circle (`○`) and checkmark (`✓`) are also strong candidates.

## Anti-patterns

Do not use:
- Pure white or pure black as primary surfaces
- Saturated primary colors (pure red, blue, green)
- Sharp, pixel-perfect geometric marker shapes
- Gradients, glossy highlights, glassmorphism, drop-shadow depth
- Generic checkmark-on-colored-square (every todo app uses this)
- Calendar-page clichés: torn edges, spiral binding, big numeric "1"
- Mascots or characters

## Concept directions to explore

Three starting points — the designer is encouraged to push past these.

1. **The single dot.** A hand-drawn ink dot on cream paper, possibly with
   faint dot-grid texture. The most essential unit of the product. Risk:
   may feel too minimal at favicon size.

2. **Handwritten "p".** A lowercase `p` rendered in Patrick Hand style,
   with pen-on-paper irregularity. Monogrammatic, branded, distinctive.
   Could incorporate a marker element (e.g. a dot above the stem).

3. **"p" + marker fusion.** A `p` where the counter (the enclosed space)
   holds a marker symbol — a filled dot, or an open circle for an event
   feel. Combines brand and product vocabulary in a single mark.

## Deliverables

- Master vector (SVG)
- iOS icon set: 1024×1024 master down to 40×40
- Android adaptive icon: foreground + background layers, 108×108 dp
- macOS icon set: 1024×1024 down to 16×16
- Favicon: 32×32 and 16×16 PNG
- Optional: dark-surface variant for adaptive dark contexts

## Technical notes

- iOS auto-applies a rounded-rect mask — **don't pre-round**
- Android adaptive icons must survive either a circular OR squircle mask
  — keep critical elements inside the 66% safe zone
- At 16×16 the mark should still read as "something handwritten on paper."
  If the concept only works large, rework.
- The icon will sit on a cream or dark square — avoid designs that only
  work on transparent canvas.

## Out of scope

- The wordmark "planyr" in Patrick Hand already exists on the landing
  page (`planyr.day`). It may appear alongside the icon where sensible,
  but is not the icon itself.

## References

- Live landing page: https://planyr.day (tone, palette, dot-grid)
- OG image: `infra/landing/og-image.png` (fonts, marker glyphs in use)
- Design system: `docs/design/README.md`, `tokens.md`, `markers.md`
