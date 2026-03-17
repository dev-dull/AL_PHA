# AlPHA — Comprehensive Testing Strategy

## Overview

This document defines the full testing strategy for AlPHA (Alastair Planner & Habit App), a cross-platform Flutter application (Android, iOS, Web) backed by AWS services. The strategy covers every layer from isolated unit tests through to end-to-end flows spanning frontend and backend.

---

## 1. Unit Testing

### 1.1 Flutter Unit Tests — Business Logic & Data Models

**Scope:** Pure Dart code with no widget tree or platform dependencies. Run on the Dart VM in milliseconds.

**Entities under test:**

| Entity | Key behaviors to test |
|--------|----------------------|
| `Board` | Creation with type (DAILY, WEEKLY, MONTHLY, YEARLY, CUSTOM), archiving, serialization to/from JSON |
| `Column` | Ordering via `position`, type classification, label validation |
| `Task` | State transitions (OPEN → IN_PROGRESS → COMPLETE, OPEN → MIGRATED, OPEN → CANCELLED), priority assignment, deadline handling, recurrence rule parsing |
| `Marker` | Symbol cycling logic (empty → DOT → CIRCLE → X → empty), timestamp tracking |

**State management tests:**

- **Board state:** Loading, creating, archiving boards. Adding/removing columns emits correct states.
- **Task state:** Adding, reordering (position changes), completing (state = COMPLETE, `completed_at` set), migrating.
- **Marker state:** Setting at a task-column intersection, cycling through symbol values, removing markers, context shifting.
- **Migration logic:** Given N incomplete tasks, verify migration creates new tasks in target board, marks originals with MIGRATED state and `>` symbol.

**Additional areas:**
- Recurrence rule (RRULE) parsing and next-occurrence calculation
- Board template instantiation
- Input validation (empty task titles, duplicate column labels, max column count)
- Sorting and filtering logic

**Test file organization:**

```
test/
  models/
    board_test.dart
    column_test.dart
    task_test.dart
    marker_test.dart
  state/
    board_notifier_test.dart
    task_notifier_test.dart
    marker_notifier_test.dart
    migration_notifier_test.dart
  services/
    board_repository_test.dart
    sync_service_test.dart
    template_service_test.dart
  utils/
    recurrence_parser_test.dart
    position_calculator_test.dart
```

### 1.2 Backend Unit Tests — Lambda / Service Functions

**Scope:** Each Lambda handler tested in isolation with mocked AWS SDK clients.

| Lambda / Function | Test cases |
|-------------------|------------|
| `createBoard` | Valid creation, duplicate name handling, max board limit, schema validation |
| `addTask` | Append to board, position auto-increment, board-not-found error |
| `setMarker` | Valid symbol values, invalid task-column pair, idempotent upsert |
| `removeMarker` | Existing marker removal, no-op on non-existent marker |
| `completeTask` | State transition to COMPLETE, `completed_at` timestamp set, idempotency |
| `migrateTask` | Cross-board migration, source task marked MIGRATED, new task created |
| `shiftContext` | Atomic remove-from-old + add-to-new column marker |
| `reorderTask` | Position swap logic, concurrent reorder conflict |
| `archiveBoard` | Soft delete flag, cascading marker/task archival |

---

## 2. Widget Testing

**Scope:** Flutter widget tests using `testWidgets`. Simulated framework binding, no real device.

### 2.1 Grid / Matrix View

- **Rendering:** Given a Board with 5 columns and 10 tasks, verify 50 cells render, correct labels and titles.
- **Scroll behavior:** Verify horizontal scrollability when columns exceed viewport.
- **Empty state:** Board with zero tasks shows empty-state message.
- **Dense board:** Board with 30+ columns renders without overflow errors.

### 2.2 Marker Cycling Interaction

- **Single tap:** Verify cycle: empty → DOT → CIRCLE → X → empty.
- **Long press:** Opens full marker picker with STAR, TILDE, MIGRATED options.
- **Visual feedback:** Each marker symbol renders the correct icon.

### 2.3 Drag-to-Reorder

- Simulate long-press-and-drag with `TestGesture`. Verify position changes.
- Boundary conditions: drag to top, to bottom, single task (no-op).

### 2.4 Swipe-to-Complete

- Swipe right → COMPLETE with strikethrough visual.
- Undo via snackbar reverts state.
- Already-complete task: swipe is no-op.

### 2.5 Migration Flow Dialogs

- Prompt trigger when period has ended and incomplete tasks exist.
- Task selection checklist with Select All / Deselect All.
- Confirm creates tasks in new board, marks originals with `>`.
- Cancel dismisses with no side effects.
- Zero incomplete → no prompt.

---

## 3. Visual / Golden Testing

### 3.1 Tooling

`golden_toolkit` package (or `alchemist` for multi-theme/multi-device support).

### 3.2 Screens to Capture

| Screen | Variants |
|--------|----------|
| Board grid view | Empty, populated (5 cols / 10 tasks), dense (31 cols / 50 tasks) |
| Marker cell states | All 6 marker symbols |
| Migration dialog | 3 tasks selected, 0 tasks |
| Board creation form | Initial state, validation error |
| Task detail sheet | All fields, minimal fields |
| Settings / column editor | 5 custom columns |

### 3.3 Breakpoints

| Target | Resolution |
|--------|-----------|
| Phone portrait | 375x812 |
| Phone landscape | 812x375 |
| Tablet | 1024x768 |
| Web desktop | 1440x900 |
| Web narrow | 768x1024 |

### 3.4 Managing Goldens Across Platforms

1. **Generate goldens exclusively on CI** (Linux). Never commit locally-generated goldens.
2. Store in `test/goldens/` organized by screen and variant.
3. CI job runs `flutter test --update-goldens` on a pinned Docker image.
4. Pixel-diff tolerance of 0.5%.
5. Consider `alchemist` for platform-independent rendering.

### 3.5 Theme Variants

Capture each screen in both light and dark themes.

---

## 4. Integration Testing

**Scope:** Tests on real devices or emulators using the `integration_test` package.

### 4.1 Key User Flows

| Flow | Steps | Assertions |
|------|-------|------------|
| **Board lifecycle** | Create board → verify columns → add tasks → verify grid → archive → verify disappears | Board appears/disappears, grid renders |
| **Marker workflow** | Tap cell → verify DOT → tap → CIRCLE → tap → X → tap → empty | Icons match cycle |
| **Context shift** | Mark "Email" → mark "Waiting For" → cross off Email | Both cells correct |
| **Complete task** | Swipe right → verify strikethrough + COMPLETE state | Visual + data match |
| **Migration** | Create board → add 5 tasks → complete 2 → migrate 3 → verify new board | Cross-board integrity |
| **Reorder** | Add A,B,C,D,E → drag C to pos 1 → verify C,A,B,D,E | List order correct |
| **Offline resilience** | Toggle airplane mode → add task → verify local → restore → verify sync | Optimistic UI + sync |

### 4.2 Running on Devices

- **Android:** Firebase Test Lab or local emulator (API 30+)
- **iOS:** Xcode Simulator (iPhone 15 Pro, iOS 17)
- **Web:** `chromedriver` with `flutter drive`

### 4.3 Performance Profiling

- Grid initial render under 500ms on mid-range device.
- Scrolling 50-task board at 60fps.
- Marker tap response under 100ms.

---

## 5. Platform-Specific UI Testing

### 5.1 Material vs Cupertino

Verify correct platform components via integration tests with platform-specific assertions.

### 5.2 Web Responsive Layout

Test at each breakpoint (< 768, 768-1200, > 1200) using `MediaQuery` overrides.

### 5.3 Horizontal Scroll on Mobile

- Verify sticky first column remains visible during horizontal scroll.
- Verify scroll indicators on web.

### 5.4 Pinch-to-Zoom

- Simulate two-finger pinch, verify scale factor changes.
- Verify min/max zoom boundaries.
- Web: verify Ctrl+scroll triggers zoom.

### 5.5 Platform-Specific Gestures

| Gesture | Android/iOS | Web |
|---------|-------------|-----|
| Tap-to-mark | Touch tap | Mouse click |
| Long-press picker | Touch long-press | Right-click |
| Swipe-to-complete | Touch swipe | Button (no swipe) |
| Drag-to-reorder | Touch long-press + drag | Mouse drag |
| Pinch-to-zoom | Two-finger pinch | Ctrl + scroll |

---

## 6. API / Backend Testing

### 6.1 API Endpoint Testing

Test all CRUD endpoints with valid/invalid payloads, auth checks (401/403), and edge cases.

### 6.2 Contract Testing

1. Define API contracts using OpenAPI 3.0.
2. Backend: validate Lambda responses conform to schema.
3. Frontend: generate Dart models from OpenAPI spec, test serialization.
4. CI gate: schema diff check on every PR modifying API models.

### 6.3 Load Testing

**Tool:** k6 or Artillery.

| Scenario | Target | Success criteria |
|----------|--------|-----------------|
| Steady state | 100 concurrent users, marker toggles every 2s | p95 < 200ms, 0% errors |
| Board creation burst | 50 simultaneous board creates | All succeed within 5s |
| Migration spike | 30 users migrating 20 tasks each | All complete, data intact |
| Read-heavy | 500 concurrent users viewing boards | p95 < 100ms |

---

## 7. End-to-End Testing

### 7.1 Tool

- Mobile: Flutter `integration_test` against staging backend
- Web: Playwright or Cypress

### 7.2 Critical User Journeys

**Journey 1: New User Onboarding** — Sign up → verify email → onboarding → create first board → add task → place marker → verify persistence after restart.

**Journey 2: Full Week Workflow** — Log in → open board → add 10 tasks → mark across columns → complete 6 → migrate remaining 4 → verify both boards.

**Journey 3: Cross-Device Sync** — Log in on Device A → create board → log in on Device B → verify board → mark cell on A → verify on B within 5s.

**Journey 4: Context Shifting** — Open GTD board → add task → mark Phone → cross off Phone → mark Waiting For → verify both cells.

**Journey 5: Offline Sync** — Log in → disconnect → add tasks + markers → reconnect → verify sync → verify on second device.

### 7.3 Test Data Isolation

Each E2E run creates a unique test user (`test-{uuid}@alpha-test.example.com`). Cleanup Lambda deletes user and data after run.

---

## 8. Test Data & Fixtures

### 8.1 Static Fixtures (in `test/fixtures/`)

| Fixture file | Contents |
|--------------|----------|
| `empty_board.json` | Board with 7 columns, 0 tasks |
| `weekly_board_populated.json` | Board with 7 columns, 15 tasks, various marker states |
| `monthly_board_dense.json` | Board with 31 columns, 50 tasks |
| `migration_source_board.json` | 10 tasks: 4 complete, 3 in-progress, 3 open |
| `all_marker_types.json` | One marker per type |

### 8.2 Dynamic Fixtures

`BoardFactory` / `TaskFactory` builder classes with sensible defaults and overrides.

### 8.3 Backend Seeding

- `seed.sh` script populates DynamoDB for test users before test suites.
- Idempotent via condition expressions.
- Cleanup via `BatchWriteItem` after tests.

---

## 9. Test Environments

### 9.1 Which Tests Run Where

| Test type | Local | CI (PR) | CI (merge) | Staging | Prod |
|-----------|-------|---------|------------|---------|------|
| Unit tests (Flutter) | Yes | Yes | Yes | -- | -- |
| Unit tests (Backend) | Yes | Yes | Yes | -- | -- |
| Widget tests | Yes | Yes | Yes | -- | -- |
| Golden tests | -- | Yes | Yes | -- | -- |
| Integration tests | Optional | Yes | Yes | -- | -- |
| Contract tests | -- | Yes | Yes | -- | -- |
| API endpoint tests | -- | -- | Yes (dev) | Yes | -- |
| E2E tests | -- | -- | -- | Yes | -- |
| Load tests | -- | -- | -- | Yes | -- |
| Smoke tests | -- | -- | -- | -- | Yes |

### 9.2 CI Pipeline Structure

```
PR:
  1. Lint (flutter analyze, dart format)
  2. Unit tests
  3. Widget tests
  4. Golden tests (Linux runner)
  5. Backend unit tests
  6. Contract tests
  --- All must pass to merge ---

Merge to main:
  1. All PR checks (re-run)
  2. Build Android APK, iOS IPA, Web bundle
  3. Integration tests (emulator + simulator + Chrome)
  4. Deploy to staging
  5. E2E tests against staging
  --- All must pass for release candidate ---

Release:
  1. Deploy to prod
  2. Smoke tests (read-only)
  3. Synthetic monitoring begins
```

---

## 10. Coverage Targets & Quality Gates

### 10.1 Coverage Thresholds

| Layer | Minimum | Target |
|-------|---------|--------|
| Data models | 95% | 100% |
| State management | 90% | 95% |
| Repositories / Services | 85% | 90% |
| Backend Lambdas | 90% | 95% |
| Widget tests | 70% | 80% |
| Overall Flutter | 80% | 85% |
| Overall backend | 85% | 90% |

### 10.2 Release Blockers

1. Any unit test fails.
2. Any widget test fails.
3. Golden test diff exceeds 0.5% without explicit approval.
4. Any integration test fails on any platform.
5. Any E2E test fails on staging.
6. Code coverage drops below minimum thresholds.
7. `flutter analyze` reports any error-level issues.
8. Backend contract tests fail.
9. Load test p95 latency exceeds SLA (200ms writes, 100ms reads).
10. Security scan finds high/critical vulnerabilities.

### 10.3 Metrics to Track

- **Test count** by category — should grow with features.
- **CI execution time** — PR checks under 10 min, integration + E2E under 30 min.
- **Flaky test rate** — >2% flake rate in 30 days → must fix or quarantine.
- **Time-to-green** — median time from PR push to all checks passing.
- **Coverage trend** — plotted weekly, declining coverage triggers tech-debt sprint.

### 10.4 Flaky Test Policy

1. Flagged when failing on CI without code changes.
2. Quarantined to `test/quarantine/` within 24 hours.
3. Quarantined tests don't block PRs but are tracked in a dedicated issue.
4. Must be fixed or deleted within 2 sprints.

---

## Appendix: Test Naming Conventions

All tests follow: `[unit under test] [condition] [expected behavior]`.

Examples:
- `Task when state is OPEN and completeTask is called should transition to COMPLETE`
- `MarkerCell when tapped on empty cell should display DOT symbol`
- `MigrationDialog when all tasks are complete should not appear`
- `BoardGrid when columns exceed viewport width should be horizontally scrollable`
