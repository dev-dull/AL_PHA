# Multi-Agent Coordination Guide

## Overview

AlPHA uses Claude Code agents for parallel development. Each agent operates in its own session with access to the full repo. This guide prevents agents from breaking each other's work.

## Current State (as of March 2026)

- **MVP:** Complete — offline-first Flutter app with 111 tests
- **Schema:** Drift/SQLite v8 (RecurringSeries, SeriesTags, Tasks.seriesId)
- **Backend:** Not started — RDS Postgres + Lambda (Python) + Cognito planned
- **Infrastructure:** Terraform planned but not implemented

## Agent Roles

### Frontend Agent (SE)
**Owns:** `lib/`, `test/`, `pubspec.yaml`, `fonts/`

**Before making changes:**
- Read `CLAUDE.md` for conventions
- Run `flutter test` to confirm baseline passes
- Run `flutter analyze --fatal-infos` to confirm zero issues

**After making changes:**
- Run `flutter test` — all tests must pass
- Run `flutter analyze --fatal-infos` — zero issues
- Run `dart run build_runner build --delete-conflicting-outputs` if you touched Freezed models, Drift tables, or Riverpod providers
- Commit with conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`)

**Key files to understand first:**
- `lib/shared/database.dart` — Drift schema (currently v8)
- `lib/shared/providers.dart` — all repository providers
- `lib/features/series/` — virtual instances (the newest, most complex subsystem)
- `lib/features/marker/providers/marker_providers.dart` — migration logic
- `lib/features/board/presentation/board_grid_body.dart` — largest UI file

**Known fragile areas:**
- Recurring task materialization — timing-sensitive, read from DB not providers in initState
- Tag sync between `task_tags` and `series_tags` — must update both
- First-day-of-week — board lookup uses ±1 day fallback
- Auto-save on dismiss — callbacks must be `Future<void> Function()`, not `void Function()`

### Backend Agent (BE)
**Owns:** `lambda/`, `infra/`, `infra/migrations/`

**Before starting:**
- Read `docs/plan-cloud-sync.md` for the full architecture
- Backend uses Python 3.12, Postgres, Flyway, Terraform

**Coordination with SE:**
- The Postgres schema must mirror Drift schema v8 + sync columns (`user_id`, `deleted_at`, `sync_cursors`)
- File GitHub Issues for any schema mismatches
- API contract (endpoints, request/response shapes) must be agreed before implementation

**Key decisions already made:**
- Lambda runtime: Python 3.12 (psycopg2-binary)
- Schema migrations: Flyway (Docker in CI)
- Auth: Cognito hosted UI
- Sync: timestamp scan, per-field last-write-wins
- IaC: Terraform (not CDK)

### QA Agent
**Owns:** `test/`, test strategy

**Before writing tests:**
- Read existing tests in `test/models/` and `test/widget/` for patterns
- Use `AlphaDatabase.forTesting(NativeDatabase.memory())` for DB tests
- Use `ProviderContainer` with `alphaDatabaseProvider` override
- Read from DB directly (not providers) in tests that run before providers settle

**Test requirements:**
- All tests must pass: `flutter test`
- Widget tests that use `TaskDetailSheet` need `taskNoteRepositoryProvider` override (Drift stream timer issue)
- Use tall viewport (`Size(800, 1600)`) for tests that tap buttons below the fold

### DevOps Agent (DO)
**Owns:** `.github/workflows/`, `infra/`, `docs/vm-spec.md`

**Current CI:** `.github/workflows/ci.yml` — lint, analyze, test, build APK/IPA

**Planned:**
- Terraform workflows for `infra/` changes
- Flyway migration workflows for `infra/migrations/` changes
- Lambda deploy workflows for `lambda/` changes

### Product Designer (PD)
**Owns:** `lib/app/theme.dart`, `lib/design_system/`, `fonts/`

**Current theme:** Bullet journal aesthetic — Patrick Hand font, cream paper palette, ink marker colors. Dark mode supported.

**Design tokens:** `lib/app/theme.dart` (AlphaTheme class)

## File Ownership

| Path | Owner | Others may read, but file issues before editing |
|------|-------|------------------------------------------------|
| `lib/features/*/` | SE | BE may propose API-aligned changes via issues |
| `lib/shared/database.dart` | SE | BE must review schema changes |
| `lib/shared/providers.dart` | SE | — |
| `lib/app/theme.dart` | PD | SE implements token changes |
| `lambda/` | BE | — |
| `infra/` | DO/BE | — |
| `infra/migrations/` | BE | DO runs in CI |
| `.github/workflows/` | DO | — |
| `test/` | QA/SE | Both can add tests |
| `docs/` | Any | — |

## Coordination Protocol

### Before Starting Work
1. Check open GitHub Issues for context
2. Read `CLAUDE.md` (always loaded in context)
3. Run `flutter test` to confirm clean baseline
4. If working on a feature that crosses file ownership, file an Issue first

### Branch Strategy
- **Main branch:** Protected. Agents push directly for now (branch protection bypassed on free plan).
- **Feature work:** Prefer feature branches for large changes. Name: `feature/<issue>-<description>` or `fix/<issue>-<description>`.
- **Hotfixes:** Can go directly to main with a clear commit message.

### Communication
- File GitHub Issues for cross-agent coordination
- Use conventional commit messages so other agents can parse history
- When changing shared files (`database.dart`, `providers.dart`, `theme.dart`), note the change in the commit message body

### Schema Changes
1. SE bumps Drift schema version in `database.dart`, adds migration
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. BE adds corresponding Flyway migration in `infra/migrations/`
4. Both commit and reference each other's changes

### Test Requirements
- **Minimum:** All existing tests pass before pushing
- **New features:** Must include at least one smoke test
- **Bug fixes:** Must include a regression test

## Existing Role Docs (Reference Only)

The files in `docs/roles/` contain the original 12-week sprint plan from before the MVP. They are **partially outdated** but useful as reference:

| File | Status | Notes |
|------|--------|-------|
| `software-engineer.md` | Sprints 1-4 done | References "Isar" → now "Drift". Sync/auth not started. |
| `backend-engineer.md` | Not started | References CDK/DynamoDB/AppSync → now Terraform/RDS/REST. See `plan-cloud-sync.md` instead. |
| `qa-engineer.md` | Partially done | Test pyramid still valid. Coverage targets still apply. |
| `devops-engineer.md` | Partially done | CI pipeline exists. Dogfood/stage/prod pipelines not yet. |
| `product-designer.md` | Mostly done | Theme shipped. Accessibility specs still apply. |
| `project-lead.md` | Reference | RACI matrix and meeting cadence still valid for team coordination. |

## Quick Reference

```bash
# Before any work:
flutter test
flutter analyze --fatal-infos

# After Freezed/Drift/Riverpod changes:
dart run build_runner build --delete-conflicting-outputs

# After all changes:
flutter test
flutter analyze --fatal-infos
git add <files>
git commit -m "feat: description"
git push

# Delete local test DB if schema changed:
rm ~/Library/Containers/com.alpha.alpha/Data/Documents/alpha.db
```
