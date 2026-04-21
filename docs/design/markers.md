# Markers

The marker system is the product. Six symbols, each with a specific
meaning, a specific ink color, and a specific rendering strategy.

## The six

| Symbol | Name | Meaning | Cycles to |
|:------:|------|---------|-----------|
| (empty) | — | no status set | • |
| • | dot | scheduled for this day | / |
| / | slash | in progress | ✓ |
| ✓ | x (check) | done | (empty) |
| > | migrated forward | not completed; carried to next week | — (toggle only) |
| < | done early | completed before its scheduled day | — (auto-filled) |
| ○ | event | an event (vs. a task) | (own cycle) |

### Cycle rules

- Tapping an empty day cell on a task row sets `•` (or `○` for events)
- Tapping an existing marker opens the **radial picker** to pick a new
  symbol or clear
- The migration column (`>`) is a simple toggle: empty ↔ `>`
- Marking `✓` on day N auto-fills `<` on any remaining `•` cells that
  week (task was done early, subsequent dots aren't missed)
- Reverting `✓` reverts the auto-filled `<` back to `•`

### Past days

On past days, an empty task cell sets `>` instead of `•` when tapped —
past dots that were never acted on are implicitly missed, and the
migration marker is the correct state.

## Rendering

Hand-drawn feel is the whole point. Don't use perfect geometric shapes
or glyphs where we have a painter.

| Symbol | Rendering | File |
|--------|-----------|------|
| • | `CustomPaint` (`_InkDotPainter`) — filled ink circle with slight jitter | `marker_cell.dart` |
| ✓ | `CustomPaint` (`_InkCheckPainter`) — hand-drawn checkmark stroke | `marker_cell.dart` |
| ○ | `CustomPaint` (`_InkCirclePainter`) — open circle with irregular stroke | `marker_cell.dart` |
| / | Patrick Hand text glyph | `marker_cell.dart` |
| > | Patrick Hand text glyph | `marker_cell.dart` |
| < | Patrick Hand text glyph | `marker_cell.dart` |

Colors for each symbol are listed in [tokens.md](./tokens.md#markers--light-theme).

## Migration column

The `>` column on the far right of the board has special behavior:

- **Regular task** with `>` marker → plain `>` glyph
- **Regular task** that is recurring → `autorenew` icon (non-tappable; the
  recurrence handles migration automatically)
- **Event** (any state) → calendar icon (`event`) or repeat-calendar icon
  (`event_repeat`) for recurring events
- Event calendar icons appear **at reduced opacity** when no marker is set
  and full opacity when a `>` has been placed

The goal: at a glance, a designer or user can tell whether a row is a
task or event, and whether it repeats.

## Radial picker

When a cell already has a marker, tapping opens a radial popup with all
available symbols arranged around the cell. Implementation:

- File: `lib/features/marker/presentation/marker_cell.dart`
- Radius: 64 px
- Item size: 44 px
- Animation: `Curves.easeOutBack`, 200 ms
- Items start at top (-π/2) and fan clockwise
- Always includes a "clear" option (`∅`)

On day columns the picker shows all six symbols plus clear; on the
migration column it shows only `>` plus clear.

## Events

Events are tasks with `isEvent = true`. They default to `○` markers on
day columns. Tapping a day cell on an event row does **not** cycle —
it opens the event editor instead, since changing scheduled days of an
event is a semantic change, not a marker change.

## Designer rules

- Don't introduce new marker symbols without a semantic justification
- Don't redefine what a symbol means
- Don't use marker glyphs for decoration outside the grid (breaks the
  symbol-as-status contract)
- Dot (`•`) is the most common state on any given board — make sure new
  surfaces accommodate dense `•` without crowding
