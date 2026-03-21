# AlPHA — Alastair Planner & Habit App

A cross-platform productivity app implementing **The Alastair Method** — a matrix-based task management system inspired by the bullet journal technique.

Built with Flutter (macOS, iOS, Android, Web). Currently offline-first with local Drift/SQLite storage.

## Features

- **Weekly board grid** — day columns (M T W T F S S) on the left, task names on the right, migration column (>) on the far left
- **Marker cycling** — tap to cycle: empty → dot (•) → slash (/) → done (✓) → empty
- **Auto-fill logic** — done early (<) fills remaining scheduled days; missed days auto-migrate (>)
- **Migration** — toggle > to push a task to next week, carrying its day-of-week schedule as dots
- **Events** — dedicated event editor with day-of-week picker, scheduled time, and iCal RRULE recurrence
- **Monthly overview** — calendar with color-coded dots (green/red/orange/blue) based on task completion
- **Yearly overview** — 12 mini-month heatmap grids with red→green completion gradient
- **Bullet journal theme** — Patrick Hand font, cream paper palette, ink-on-paper aesthetics
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
- **Local DB:** Drift (SQLite), schema v5
- **Project structure:** Feature-first (`lib/features/{board,task,marker,column,migration}/`)

See [CLAUDE.md](CLAUDE.md) for the full project guide.
