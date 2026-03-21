# AlPHA — Claude Code Project Guide

## What is this project?

AlPHA (Alastair Planner & Habit App) is a cross-platform productivity app implementing "The Alastair Method" — a matrix-based task management system. Built with Flutter (Android, iOS, Web) and backed by AWS.

## Repository

- **Remote:** git@github.com:dev-dull/AL_PHA.git
- **Owner:** dev-dull (Alastair)
- **Visibility:** Public

## Current Phase: MVP Complete (Offline-First, No Backend)

All 8 redesign phases are complete, plus additional post-MVP features:
- **Phase 1:** New Alastair Method symbols — dot (•), slash (/), x (✓), migratedForward (>), doneEarly (<), event (○)
- **Phase 2:** Fixed weekly columns (M T W T F S S >), removed templates and column management
- **Phase 3:** Grid layout flip — day columns on left, task names on right
- **Phase 4:** Auto-fill logic — < for done early, > for missed days
- **Phase 5:** Task sorting (manual, priority, deadline, date entered, alphabetical)
- **Phase 6:** Bullet journal theme (Patrick Hand font, cream paper palette, ink-like marker colors)
- **Phase 7:** Migration simplification (auto-migration on week change, per-task dot schedule carry-over)
- **Phase 8:** Multi-period views (weekly, monthly, quarterly, yearly — all fully functional)

The app includes:
- Flutter project scaffold (feature-first, Riverpod, GoRouter, Freezed, Drift)
- Auto-created weekly boards with chevron navigation between weeks
- Monthly view (W1–W5 columns), quarterly view (M1–M3), yearly view (Q1–Q4)
- Board grid/matrix view with day columns on left, task names on right
- Radial/circular marker menu (tap empty → dot, tap existing → radial picker)
- Auto-fill markers: < (done early) and > (missed days), with per-task migration
- Migration column as simple toggle (empty ↔ >) — manually setting > pushes task to next period
- Add/edit/delete tasks, drag-to-reorder, swipe-to-complete/cancel
- Bullet journal theme with handwritten font and ink-on-paper aesthetics
- Local persistence with Drift (SQLite)
- Dark mode with theme-aware marker colors
- Basic CI pipeline (lint, test, build verification)
- 87 tests (unit + widget)

**Not in scope yet:** AWS backend, auth, sync, subscriptions, onboarding, recurring tasks.

## Architecture

### State Management: Riverpod v2
- Use `@riverpod` annotation (code generation) for all providers
- Granular providers: `markerProvider(taskId, colId)` for per-cell rebuilds
- Repository pattern: providers → repositories → data sources (Drift/SQLite)
- MarkerActions handles auto-fill logic (done-early `<` and missed `>` markers)

### Navigation: GoRouter
- Declarative routes in `lib/app/router.dart`
- Deep linking support (critical for web)

### Data Models: Freezed + JSON Serialization
- Immutable models in `lib/features/<feature>/domain/`
- JSON serialization for DB and future API compatibility

### Local DB: Drift (SQLite) — Schema v3
- Isar was planned but has incompatible dependencies with Freezed v3 (source_gen conflict)
- Tables defined in `lib/shared/database.dart` with `@DataClassName('...Row')` to avoid name collisions
- Drift data classes use `*Row` suffix (BoardRow, TaskRow, etc.), domain models are Freezed
- Repository classes in `lib/features/<feature>/data/` convert between Row ↔ domain
- After code changes, run: `dart run build_runner build --delete-conflicting-outputs`

## Build & Run

### Prerequisites
- Flutter SDK (stable channel, 3.41+)
- Dart SDK 3.11+
- CocoaPods (for macOS/iOS): `brew install cocoapods`
- Java 17 (for Android builds)

### Quick Start
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos    # or: flutter run -d chrome, flutter run -d <device>
```

### Code Generation
After modifying Freezed models, Drift tables, or Riverpod providers:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running Tests
```bash
flutter test                    # all tests
flutter test test/models/       # unit tests only
flutter test test/widget/       # widget tests only
```

### Linting
```bash
dart format .
flutter analyze --fatal-infos
```

### Project Structure (Feature-First)
```
lib/
├── app/                    # App entry, router, theme
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── design_system/          # Shared UI components, tokens
│   ├── tokens/
│   └── widgets/
├── features/
│   ├── board/
│   │   ├── data/           # Drift repositories
│   │   ├── domain/         # Freezed models, enums
│   │   ├── presentation/   # Screens, widgets
│   │   └── providers/      # Riverpod providers
│   ├── task/
│   ├── marker/
│   ├── column/
│   ├── migration/
│   └── views/              # Future view stubs (if any)
├── shared/                 # Cross-feature utilities (week_utils, period_utils, DB, providers)
test/
├── models/
├── state/
├── widget/
├── fixtures/
```

## Conventions

### Code Style
- `dart format` with default line length (80)
- `flutter analyze --fatal-infos` must pass
- Feature-first file organization
- Freezed for all domain models
- Riverpod code generation (`@riverpod`) for providers

### Git
- Branch from `main`: `feature/ALP-<issue>-<description>` or `fix/ALP-<issue>-<description>`
- Conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`
- Squash merge to `main`
- Never force push to `main`

### Testing
- Test naming: `[unit] [condition] [expected behavior]`
- Fixtures in `test/fixtures/`
- Coverage target: 80% (MVP phase) — currently 87 tests (unit + widget)

### GitHub Issues
- Issues prefixed with `ALP-` in titles where applicable
- Labels: `mvp`, `frontend`, `backend`, `devops`, `design`, `bug`, `enhancement`
- Sub-agents file issues to exchange cross-cutting information

## AWS
- **Account:** 773469078444
- **Region:** us-west-2
- **Profile:** default

## Key Documentation
- `docs/the-alastair-method.md` — Core method research
- `docs/plan-flutter-app.md` — Frontend architecture plan
- `docs/plan-aws-backend.md` — Backend architecture plan
- `docs/plan-testing-strategy.md` — Testing strategy
- `docs/plan-cicd-release.md` — CI/CD and release plan
- `docs/roles/` — Role-based implementation guides
- `docs/vm-spec.md` — Agent runner VM specification

## Agent Runner VM
A homelab VM is being provisioned for dedicated Claude Code agent sessions.
See `docs/vm-spec.md` for specifications.
