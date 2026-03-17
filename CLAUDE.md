# AlPHA — Claude Code Project Guide

## What is this project?

AlPHA (Alastair Planner & Habit App) is a cross-platform productivity app implementing "The Alastair Method" — a matrix-based task management system. Built with Flutter (Android, iOS, Web) and backed by AWS.

## Repository

- **Remote:** git@github.com:dev-dull/AL_PHA.git
- **Owner:** dev-dull (Alastair)
- **Visibility:** Private

## Current Phase: MVP (Offline-First, No Backend)

The MVP includes:
- Flutter project scaffold (feature-first, Riverpod, GoRouter, Freezed, Isar)
- Board CRUD (create from template, list, archive)
- Board grid/matrix view (fixed task column + scrollable marker columns)
- Tap-to-cycle markers (empty → DOT → CIRCLE → X → empty)
- Add/edit/delete tasks, drag-to-reorder, swipe-to-complete/cancel
- Migration wizard (move incomplete tasks to a new board)
- 5 board templates (Weekly, Monthly, GTD Contexts, Daily Hourly, Project Tracker)
- Local persistence with Drift (SQLite)
- Dark mode
- Basic CI pipeline (lint, test, build verification)

**Not in MVP:** AWS backend, auth, sync, subscriptions, onboarding, recurring tasks.

## Architecture

### State Management: Riverpod v2
- Use `@riverpod` annotation (code generation) for all providers
- Granular providers: `markerProvider(taskId, colId)` for per-cell rebuilds
- Repository pattern: providers → repositories → data sources (Drift/SQLite)

### Navigation: GoRouter
- Declarative routes in `lib/app/router.dart`
- Deep linking support (critical for web)

### Data Models: Freezed + JSON Serialization
- Immutable models in `lib/features/<feature>/domain/`
- JSON serialization for DB and future API compatibility

### Local DB: Drift (SQLite)
- Isar was planned but has incompatible dependencies with Freezed v3 (source_gen conflict)
- Tables defined in `lib/shared/database.dart` with `@DataClassName('...Row')` to avoid name collisions
- Drift data classes use `*Row` suffix (BoardRow, TaskRow, etc.), domain models are Freezed
- Repository classes in `lib/features/<feature>/data/` convert between Row ↔ domain
- After code changes, run: `dart run build_runner build --delete-conflicting-outputs`

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
│   │   ├── data/           # Isar schemas, repositories
│   │   ├── domain/         # Freezed models, enums
│   │   ├── presentation/   # Screens, widgets
│   │   └── providers/      # Riverpod providers
│   ├── task/
│   ├── marker/
│   ├── column/
│   ├── migration/
│   └── template/
├── shared/                 # Cross-feature utilities
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
- Coverage target: 80% (MVP phase)

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
