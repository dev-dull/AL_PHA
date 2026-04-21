# Design tokens

Concrete values. Source of truth: `lib/app/theme.dart` (`PlanyrTheme`).
Update code first, then this doc.

## Surfaces — paper

Warm cream, never white. Dark is warm grey, never pure black.

| Token | Hex | Role |
|-------|-----|------|
| `paperLight` | `#F5F0E8` | primary light surface (scaffold background) |
| `paperLightVariant` | `#EDE7DA` | elevated light surface (cards, chips, inputs) |
| `paperDark` | `#2C2A26` | primary dark surface |
| `paperDarkVariant` | `#38352F` | elevated dark surface |

## Text — ink

Desaturated, warm. Dark brown on light paper; warm off-white on dark paper.

| Token | Hex | Role |
|-------|-----|------|
| `inkLight` | `#2C2520` | primary text on `paperLight` |
| `inkDark` | `#E8E0D4` | primary text on `paperDark` |

## Dot grid

Subtle background texture. Should read as "paper" without competing for
attention.

| Token | Hex | Role |
|-------|-----|------|
| `dotGridLight` | `#D5CCBC` | dots over `paperLight` |
| `dotGridDark` | `#4A453D` | dots over `paperDark` |

## Accent

Muted teal / soft green — the "washi tape highlight." Used sparingly for
primary actions, the live-sync indicator, and the accent line on the OG
image.

| Token | Hex | Role |
|-------|-----|------|
| `accentLight` | `#5B8A72` | seed color for light-mode `ColorScheme` |
| `accentDark` | `#8FBFA8` | seed color for dark-mode `ColorScheme` |

Dialog buttons, dividers, and most chrome use `ColorScheme` derivations
of the accent (`primary`, `primaryContainer`, etc.) rather than the raw
hex. Prefer `Theme.of(context).colorScheme.*` in Flutter code.

## Markers — light theme

Dark ink on cream paper. Each symbol has its own hue; legibility and
"handwritten" feel both matter.

| Symbol | Name | Hex | Semantic |
|:------:|------|-----|----------|
| • | dot | `#1A3A5C` | scheduled (not yet acted on) |
| / | slash | `#2B5E9E` | in progress |
| ✓ | x (check) | `#2D5A3D` | done |
| > | migrated forward | `#C0392B` | not completed this week; carried forward |
| < | done early | `#3D7A55` | completed before its scheduled day |
| ○ | event | `#5C3A6E` | event (vs. task) |

## Markers — dark theme

Lighter ink on dark paper. Same hue families as light; adjusted for
contrast on warm-dark surfaces.

| Symbol | Name | Hex |
|:------:|------|-----|
| • | dot | `#A8C4E0` |
| / | slash | `#6CA6E0` |
| ✓ | x (check) | `#8FC4A0` |
| > | migrated forward | `#E57373` |
| < | done early | `#8FC4A0` |
| ○ | event | `#C4A0D4` |

Note: `x` and `doneEarly` share the same dark-theme color intentionally —
both are "complete" states and read as green ink.

## Typography

| Property | Value |
|----------|-------|
| Primary family | `PatrickHand` (Google Fonts) |
| Fallback | system sans-serif (user-selectable via preferences) |
| Sizes | Material `TextTheme` defaults, with `bodyColor` / `displayColor` remapped to `ink*` |

Patrick Hand is bundled as an asset. The system-font option exists for
users who prefer legibility over aesthetic — do not design as though the
handwritten font is optional from a brand perspective.

## Spacing scale

Logical pixels. Use these tokens; don't hard-code spacing values.

| Token | Value |
|-------|-------|
| `spacingXS` | 4 |
| `spacingSM` | 8 |
| `spacingMD` | 12 |
| `spacingLG` | 16 |
| `spacingXL` | 24 |
| `spacingXXL` | 32 |

## Dimensions

| Token | Value | Role |
|-------|-------|------|
| `cellSize` | 48 | width & height of a marker cell in the weekly grid |
| `headerHeight` | 44 | top header row (day labels, app bar) |
| `taskColumnWidth` | 140 | minimum width of the task-name column |

## Component defaults

Pulled from `_buildTheme()`. Designers can assume these without asking.

- **AppBar:** no elevation, background = surface, left-aligned title
- **FAB:** background = `primaryContainer`, foreground = `onPrimaryContainer`
- **Card:** 0 elevation, 8px radius, fill = `surfaceContainerHighest`
- **Divider:** `onSurface` at 12% opacity
- **Input field:** 8px radius, 20% border opacity, filled with `surfaceContainerHighest`
