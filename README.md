# AlPHA — Alastair Planner & Habit App

A cross-platform weekly planner app. See your whole week at a glance, mark each day, migrate what you don't finish.

Built with Flutter (macOS, iOS, Android, Web). Currently offline-first with local Drift/SQLite storage.

## Features

- **Weekly board grid** — day columns (M T W T F S S) on the left, task names on the right, migration column (>) on the far left
- **Hand-drawn markers** — dot (filled circle), slash (/), checkmark (painted stroke), event (open circle) — all rendered with custom painters for a handwritten aesthetic
- **Radial marker menu** — tap to cycle or pick from a radial popup (dot, slash, done, clear)
- **Auto-fill logic** — done early (<) fills remaining scheduled days; missed days auto-migrate (>)
- **Migration** — toggle > to push a task to next week, carrying its day-of-week schedule as dots
- **Recurring tasks** — set repeat schedule (daily, weekly with day picker); tasks auto-populate on new week boards with autorenew icon in the migration column
- **Events** — dedicated event editor with day-of-week picker, scheduled time, and iCal RRULE recurrence
- **Task notes** — timestamped freeform notes per task (multi-line, reverse chronological)
- **Color-coded tags** — up to 12 user-defined tags with curated palette, max 4 per task, 2x2 colored badge; filter by tag from the legend bar (AND logic)
- **Won't Do** — mark tasks as "won't do" (strikethrough, locked markers, blocked from migration, unsets >); reopenable
- **Auto-save** — dismiss the editor to save; Cancel to discard
- **Responsive** — board grid scrolls horizontally at narrow/mobile widths
- **Series editing** — "this one or all" prompt for recurring tasks/events propagates across all boards
- **Monthly overview** — calendar with color-coded dots (green/red/orange/blue) based on task completion
- **Yearly overview** — 12 mini-month heatmap grids with day numbers and red→green completion gradient
- **Preferences** — font (handwritten/system), appearance (light/dark/system), first day of week (Monday/Sunday), tag management
- **Data export** — JSON export of all boards, tasks, markers, notes, and tags
- **Handwritten aesthetic** — Patrick Hand font, cream paper palette, ink-on-paper look
- **Dark mode** — theme-aware marker colors and design tokens

## Quick Start

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos    # or: chrome, ios, android
```

## Running Tests

```bash
flutter test
```

## Architecture

- **State management:** Riverpod v2 with code generation (`@riverpod`)
- **Navigation:** GoRouter with declarative routes
- **Data models:** Freezed + JSON serialization
- **Local DB:** Drift (SQLite), schema v7
- **Project structure:** Feature-first (`lib/features/{board,task,marker,column,tag,preferences,migration}/`)

See [CLAUDE.md](CLAUDE.md) for the full project guide.
