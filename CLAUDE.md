# AlPHA — Claude Code Project Guide

## What is this project?

AlPHA (Alastair Planner & Habit App) is a cross-platform productivity app implementing "The Alastair Method" — a matrix-based task management system. Built with Flutter (Android, iOS, Web) with Drift/SQLite for local persistence and AWS cloud sync (Cognito auth, RDS Postgres, Lambda, API Gateway).

> **Rename in flight:** the project will be renamed from **AlPHA** to **planyr**
> to match the acquired marketing domain `planyr.day`. The rename is planned
> but not yet executed — code, repo, AWS resources (state bucket, Cognito
> pool, etc.) still use `alpha-*` naming. Docs and this guide will switch to
> "planyr" once the rename lands.

## Repository

- **Remote:** git@github.com:dev-dull/AL_PHA.git
- **Owner:** dev-dull (Alastair)
- **Visibility:** Public
- **Domain:** `planyr.day` (landing page live; Cloudflare-hosted)

## Current Phase: Cloud Sync Complete

All 8 redesign phases are complete, plus cloud sync and auth:
- **Phase 1:** New Alastair Method symbols — dot (•), slash (/), x (✓), migratedForward (>), doneEarly (<), event (○)
- **Phase 2:** Fixed weekly columns (M T W T F S S >), removed templates and column management
- **Phase 3:** Grid layout flip — day columns on left, task names on right
- **Phase 4:** Auto-fill logic — < for done early, > for missed days
- **Phase 5:** Task sorting (manual, A-Z, next scheduled, due date, priority, date entered)
- **Phase 6:** Bullet journal theme (Patrick Hand font, cream paper palette, ink-like marker colors)
- **Phase 7:** Migration simplification (auto-migration on week change, per-task dot schedule carry-over)
- **Phase 8:** Monthly and yearly overview screens (calendar heatmaps, tap day → jump to weekly view)
- **Cloud:** AWS infrastructure (Terraform), Cognito auth, Lambda sync/migration handlers, Flutter sync client

The app includes:
- Flutter project scaffold (feature-first, Riverpod, GoRouter, Freezed, Drift)
- Auto-created weekly boards with chevron navigation between weeks
- Monthly overview (calendar heatmap showing task completion per day, events excluded from color coding)
- Yearly overview (12 mini-month grids with day numbers, red→green completion gradient, events excluded)
- Tap any day in monthly/yearly views to jump to that week's weekly view
- Board grid/matrix view with day columns on left, task names on right
- Column headers show day-of-month numbers below weekday letters
- Hand-drawn markers: dot (CustomPaint filled circle), checkmark (painted stroke), event (open circle), text symbols (/, >, <) in Patrick Hand font
- Radial marker menu with only manual symbols (dot, slash, done, clear); dot hidden on past days; arc/semi-circle layout near screen edges
- Auto-fill markers: < (done early) and > (missed days), with per-task migration
- One-time events do not migrate to next week (only recurring events migrate)
- Migration column as simple toggle (empty ↔ >) — completed tasks can also be migrated
- Recurring tasks show autorenew icon in migration column; recurring events show calendar icons; non-tappable (auto-migrate only)
- Won't Do state — tasks can be marked "Won't Do" from the editor (terminal state, strikethrough, locked markers, blocked from migration, unsets > if set); can be reopened
- Auto-save on dismiss — swiping down or tapping outside saves; explicit Cancel button to discard
- Add/edit/delete tasks, drag-to-reorder
- Full event system: dedicated event editor with description, day-of-week picker, scheduled time, iCal import (single event populates form for review; multiple imports directly) and export
- Dialogs say "event" instead of "task" for event items
- iCal import strips HTML descriptions to clean plain text (block elements, lists, entities)
- iCal import honors `DTSTART;TZID=…` parameters via the `timezone` package (IANA tzdata initialized in `main()`); the source wall-clock is converted from its named zone → UTC for storage, then displayed in the user's local zone. Without TZID we fall back to floating-local interpretation; bare `Z`-suffixed times pass through as UTC.
- Recurring events AND recurring tasks with iCal RRULE support (daily, weekly with custom day selection, monthly with multi-anchor BYMONTHDAY=N1,N2,…, yearly)
- Recurring items auto-populate on new week boards with correct marker type (dots for tasks, circles for events)
- Series edit/delete: "this one or all" prompt propagates changes across all instances on all boards
- Task notes: timestamped freeform notes per task (multi-line, reverse chronological)
- Color-coded tags: up to 12 user-defined tags (30 char max) with curated palette, max 4 per task, displayed as 2x2 colored badge in board rows
- Tag management in Settings; tag picker (FilterChips) in task detail sheet; tags carry over on migration
- Tag filtering: interactive legend bar at bottom of planner; tap tags to filter (AND logic); "Untagged" filter; "Clear" to reset
- Tags propagate to all series instances when "All" is chosen
- Preferences screen: font (handwritten/system), appearance (light/dark/system), first day of week (Monday/Sunday), tag management
- First-day-of-week affects calendar overviews and new boards; existing boards keep their column layout but display reorders columns to match preference
- JSON data export from overflow menu
- First-run "How It Works" dialog (markers, migration icons, tags key, features, settings); also accessible from overflow menu
- Responsive layout: board grid scrolls horizontally at narrow/mobile widths
- Bullet journal theme with handwritten font and ink-on-paper aesthetics
- Local persistence with Drift (SQLite)
- Dark mode with theme-aware marker colors
- DST-safe week arithmetic (calendar date math instead of Duration-based millisecond offsets)
- All timestamps stored as UTC; converted to local timezone at display time only
- **Cognito authentication** — native SRP auth (no browser redirect), in-app sign-in/sign-up/verification dialogs, token persistence with auto-refresh
- **Cloud sync** — push/pull with last-write-wins conflict resolution; sync triggers on app start, on sign-in transition, after data changes (5s debounce), on app pause/hidden/detached (flush pending writes), and on app resume (pull latest); sync indicator in app bar; Sync Now button in Settings
- **Self-healing dedupe** — if two offline devices auto-create different boards for the same week, the merge-after-pull pass in `BoardDeduper` consolidates them onto the canonical (oldest `createdAt`) and pushes a soft-delete for the duplicate
- **Tombstoned deletes** — every local hard-delete (tags, tasks, markers, notes, boards/columns, recurring series, junction rows) records a row in the schema-v10 `DeletedRecords` table; `ChangeTracker` reads tombstones since the last cursor and emits them as `deleted: true` push changes so the cloud (and other devices) drop the row instead of resurrecting it on next pull
- **iOS 18 dark + tinted app icons** — separate `appearances` variants in the AppIcon catalog (transparent-bg cream-on-dark for dark mode, white-on-transparent for tinted); generated by `assets/branding/gen_logo.py` and wired through `flutter_launcher_icons` (`image_path_ios_dark_transparent`, `image_path_ios_tinted_grayscale`)
- Basic CI pipeline (lint, test, build verification)
- 206 tests (unit + widget), zero analyzer issues

**Planned (not yet implemented):** one-time device migration (#35), subscriptions (#33), calendar integrations (#25), virtual recurring instances (#40). See `docs/infra/aws-backend.md`.

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

### Local DB: Drift (SQLite) — Schema v10
- Isar was planned but has incompatible dependencies with Freezed v3 (source_gen conflict)
- Tables: Boards, BoardColumns, Tasks, Markers, TaskNotes, Tags, TaskTags, RecurringSeriesTable, SeriesTags, SyncMeta, DeletedRecords
- Tables defined in `lib/shared/database.dart` with `@DataClassName('...Row')` to avoid name collisions
- Schema v8 added `updatedAt` to Tasks; v9 added `SyncMeta`; v10 added `DeletedRecords` (tombstones for delete sync)
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
│   │   ├── data/           # Drift repositories, data export
│   │   ├── domain/         # Freezed models, enums
│   │   ├── presentation/   # Screens, widgets
│   │   └── providers/      # Riverpod providers
│   ├── task/
│   ├── marker/
│   ├── column/
│   ├── tag/                # Color-coded tags
│   ├── preferences/        # Settings screen + persistence
│   ├── migration/
│   ├── auth/               # Cognito authentication (sign-in/up/verify)
│   └── sync/               # Cloud sync (push/pull, change tracking, indicator)
├── shared/                 # Cross-feature utilities (week_utils, period_utils, DB, providers)
test/
├── models/
├── state/
├── widget/
├── fixtures/
```

### AWS Infrastructure
```
infra/
├── main.tf              # Provider, backend config
├── variables.tf         # Environment, region
├── cognito.tf           # User pool, app client (SRP, plan_tier)
├── rds.tf               # Postgres 16, private subnet
├── api_gateway.tf       # HTTP API v2, JWT authorizer
├── lambda.tf            # 5 sync/migration functions
├── s3.tf                # Migration transfer bucket (24h TTL)
├── iam.tf               # Lambda execution roles
├── vpc.tf               # Private subnets, VPC endpoint for Secrets Manager
├── outputs.tf
├── terraform.tfvars
├── bootstrap.sh         # Create Terraform state backend
├── teardown.sh          # Cleanup script
├── bastion/             # Standalone bastion module for DB access
└── migrations/
    ├── V001__initial_schema.sql
    └── V002__fix_tags_color_column.sql

lambda/
├── requirements.txt
├── sync_push.py         # POST /sync/push — upsert with LWW
├── sync_pull.py         # POST /sync/pull — changes in FK order
├── sync_status.py       # GET /sync/status — device list, row counts
├── migrate_upload.py    # POST /migrate/upload — S3 blob + transfer code
├── migrate_download.py  # POST /migrate/download/{code} — one-time retrieval
└── shared/
    ├── db.py            # Connection pooling, transactions
    ├── auth.py          # JWT extraction, auto-user creation
    └── response.py      # JSON serialization, epoch-second timestamps
```

### Landing page (planyr.day)

Separate Cloudflare-hosted landing site for the product domain. Lives in
`infra/landing/`, deployed via `op run --env-file=.op.env -- terraform apply`
(secrets in 1Password). Serves a static "coming soon" page from an inline
Cloudflare Worker — no S3, no CloudFront, no ACM. See
`docs/infra/landing.md`.

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
- Coverage target: 80% (MVP phase) — currently 145 tests (unit + widget)

### GitHub Issues
- Issues prefixed with `ALP-` in titles where applicable
- Labels: `mvp`, `frontend`, `backend`, `devops`, `design`, `bug`, `enhancement`, `post-mvp`, `infra`
- Sub-agents file issues to exchange cross-cutting information

## AWS
- **Account:** 773469078444
- **Region:** us-west-2
- **Profile:** default

## Key Documentation

### Top-level
- `docs/the-alastair-method.md` — Core method research
- `docs/agent-coordination.md` — Multi-agent development guide (roles, file ownership, coordination)
- `docs/roles/` — Role-based implementation guides

### App (Flutter frontend)
- `docs/app/plan-flutter-app.md` — Frontend architecture plan
- `docs/app/plan-testing-strategy.md` — Testing strategy
- `docs/app/plan-cicd-release.md` — CI/CD and release plan
- `docs/app/android-device-testing.md` — Pixel 8 Pro USB/wireless testing
- `docs/app/app-store-testing.md` — Play Store / TestFlight distribution

### Design
- `docs/design/README.md` — Design language, principles, anti-patterns
- `docs/design/tokens.md` — Colors, typography, spacing, dimensions
- `docs/design/markers.md` — The six-symbol marker vocabulary

### Infrastructure
- `docs/infra/README.md` — Infra overview, state backends, naming note
- `docs/infra/aws-backend.md` — Cloud sync & multi-device (RDS Postgres, Lambda, Cognito, Terraform)
- `docs/infra/landing.md` — planyr.day landing page (Cloudflare Worker, 1Password-based secrets)
- `docs/infra/agent-vm.md` — Agent runner VM specification

## Multi-Agent Development

This project uses Claude Code agents for parallel development. **Read `docs/agent-coordination.md` before starting work.**

Key rules:
- Run `flutter test` + `flutter analyze --fatal-infos` before AND after changes
- Run `dart run build_runner build --delete-conflicting-outputs` after touching Freezed models, Drift tables, or Riverpod providers
- File ownership: SE owns `lib/`, BE owns `lambda/` + `infra/`, DO owns `.github/workflows/`, QA owns `test/`
- Schema changes: SE updates Drift in `database.dart`, BE adds Flyway migration in `infra/migrations/`
- Cross-agent coordination: file GitHub Issues before editing files you don't own
- Bug fixes MUST include a regression test
- New features MUST include at least one smoke test

Known fragile areas (read these files carefully before editing):
- `lib/features/series/` — virtual instances, materialization, tag sync
- `lib/features/marker/providers/marker_providers.dart` — migration logic
- `lib/features/board/presentation/board_grid_body.dart` — largest UI file, virtual rendering
- `lib/features/task/presentation/task_detail_sheet.dart` — auto-save, async callbacks. **Series-prompt predicate**: only `seriesId != null || recurrenceRule != null` qualifies a task as part of a series. `migratedFromTaskId` does NOT — a one-off task carried forward via `>` is still a one-off, and conflating the two leads to a confusing "Delete entire series?" prompt for plain tasks.
- `lib/features/task/data/ical_import.dart` — `enough_icalendar` returns `DTSTART` as a naive `DateTime` (wall-clock fields, `isUtc=false`); the `TZID` parameter lives separately on the property. Calling `.toUtc()` on the naive value interprets the wall-clock as host-local — wrong for any imported event whose `TZID` differs from the host. The import resolves through `tz.TZDateTime(getLocation(tzId), …).toUtc()` first, falling back to floating-local only when no TZID and no `Z` suffix are present. `tzdata.initializeTimeZones()` must be called early (it is, in `main()`).
- `lib/features/sync/` — change tracking, push/pull ordering, timestamp conversion, dedupe (`board_deduper.dart`), tombstones (`tombstone_repository.dart`). **Three traps:** (1) raw SQL via `customStatement` bypasses Drift's change tracker — pair every raw write with `db.notifyUpdates({TableUpdate.onTable(...)})` or `Stream` watchers won't fire; (2) `weeklyBoardProvider` and `daySummariesProvider` are Future providers that cache `weekStart → boardId` and marker aggregates — after sync's dedupe replaces a board's identity, `ref.invalidate(weeklyBoardProvider)` and `ref.invalidate(daySummariesProvider)` are required or the UI keeps the stale id and shows an empty grid until re-navigation. Pair UI consumers with `.when(skipLoadingOnReload: true, ...)` to avoid a spinner flash on re-eval. (3) Hard-deletes leave nothing for `ChangeTracker`'s timestamp scan to find — every repository's `delete` method must call `_tombstones?.record(table, id)` (or `recordComposite` for junction rows) or the cloud will keep the row and resurrect it on next pull.
- `lib/main.dart` — the **container.listen on authProvider** that fires `syncNow()` on signed-out → signed-in transitions lives here on purpose. Earlier we registered it inside `Sync.build()` via `ref.listen`, but that races: a sign-in could happen before anything has read `syncProvider`, so `Sync.build` never ran and the listener never registered. Don't move it back.
- `lib/features/auth/` — token refresh, Cognito SRP flow

## Agent Runner VM
A homelab VM is being provisioned for dedicated Claude Code agent sessions.
See `docs/infra/agent-vm.md` for specifications.
