# Design

Everything in planyr's visual identity serves one metaphor: **a handwritten
weekly planner on cream paper.** Font, color, dot grid, hand-drawn markers,
warm dark mode — every choice reinforces that feeling.

Start here, then drill into the specifics:

- [Design language](#design-language) — the metaphor and its principles
- [Design tokens](./tokens.md) — concrete colors, typography, spacing, dimensions
- [Markers](./markers.md) — the six-symbol vocabulary that drives the product

## Design language

### Paper, not canvas

Surfaces are **warm cream** (`#F5F0E8`), never pure white. Dark mode is
**warm dark grey** (`#2C2A26`), never pure black. Every background carries
a subtle dot grid, echoing journal paper. Pure white or pure black breaks
the metaphor and should never appear as a large surface.

### Ink, not pixels

Marker strokes are drawn with slight irregularity (via `CustomPaint`), not
perfect geometry. Colors are desaturated and muted — think **fountain pen
on paper**, not screen RGB. Saturated primaries (`#FF0000`, `#0000FF`) are
wrong; all accents and markers sit in a desaturated "ink" range.

### Patrick Hand, by default

The handwritten font is the baseline experience. A system-font toggle lives
in preferences for accessibility or personal taste, but the brand, the OG
image, the landing page, and all launch materials assume Patrick Hand.

### One grid, many weeks

The weekly matrix — seven day columns plus a migration column (`>`) — is
the core structure. Designs should work **within** the grid, not around it.
Avoid side navigation, tab bars across the top, or anything that fights the
grid for attention.

### Tactile markers

The six-symbol marker set (`•  /  ✓  >  <  ○`) is the product. Each symbol
has its own ink color and meaning. Users tap to cycle or use a radial picker
to choose. Don't invent new markers without strong reason; don't dilute the
existing meanings.

### Motion: functional only

Paper doesn't animate. Transitions should be quick, small, and functional
(200ms, cubic-bezier standard). No parallax, no hero animations, no
entrance effects for list items. Radial picker uses `Curves.easeOutBack`
for a slight handwritten "pop" — that's the most expressive motion in the
app.

## Light and dark

Both themes share the same metaphor. Marker colors are **retuned** per
theme for legibility, not reinvented — a dark-navy dot on cream becomes a
light-navy dot on dark paper. The paper feeling carries through.

Dark mode is **warm**: dark grey with a brown/tan undertone, not blue-black
or pure grey. See `paperDark` / `inkDark` in [tokens](./tokens.md).

## Anti-patterns

Things that break the design language — don't do these:

- Pure white (`#FFFFFF`) or pure black (`#000000`) as primary surfaces
- Saturated primary colors outside of error/warning affordances
- Sharp, pixel-perfect marker glyphs
- Sans-serif body copy as the default (the system-font option is opt-in)
- Glossy surfaces, gradients, glassmorphism, neumorphism
- Hero animations, parallax, entrance transitions on list items
- Material's default blue everywhere — use the muted teal accent

## Source of truth

Token values live in `lib/app/theme.dart` (`PlanyrTheme` class). The
[tokens doc](./tokens.md) mirrors them as a human-readable reference.
**If the doc and the code disagree, the code wins** — update the doc.

Hand-drawn marker rendering lives in
`lib/features/marker/presentation/marker_cell.dart` (the
`_InkDotPainter`, `_InkCheckPainter`, `_InkCirclePainter` classes).
