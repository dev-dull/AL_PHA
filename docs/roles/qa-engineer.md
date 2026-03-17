# AlPHA — QA Engineer Implementation Plan

## 1. Role and Responsibilities

### QA Engineer Ownership

The QA Engineer is the quality gatekeeper for AlPHA. The role spans test planning, manual exploratory testing, automated E2E and integration test authoring, API testing, performance testing, visual regression review, and release sign-off.

**QA owns:**
- Overall test plan creation and maintenance for each sprint
- Manual exploratory testing on physical devices and emulators across Android, iOS, and Web
- Authoring and maintaining E2E tests (Patrol/Maestro for mobile, Playwright for web)
- Authoring and maintaining API tests using Postman/Newman collections against the AppSync GraphQL API
- Performance and load testing using k6 against the staging environment
- Golden/visual test review and approval workflow (the Software Engineer generates goldens; QA reviews diffs)
- Device farm test execution and configuration (Firebase Test Lab, BrowserStack)
- Bug triage leadership, severity assignment, and regression test enforcement
- Release QA checklist ownership and sign-off authority
- Quality metrics reporting to the team

**Software Engineer owns:**
- Unit tests (Dart VM, Flutter `test` package) for all business logic, models, state management, and repositories
- Widget tests (`testWidgets`) for individual components (MarkerCell, TaskRow, GridMatrix, etc.)
- Golden file generation (running `--update-goldens` and committing updated golden files after QA approval)
- Integration tests using `integration_test` package for core user flows
- Backend unit tests for Lambda resolvers with mocked AWS SDK clients
- Contract tests (GraphQL schema validation between frontend DTOs and backend schema)
- Test fixture creation (BoardFactory, TaskFactory, JSON fixtures)
- Adding test hooks, semantic labels, and `Key` values to widgets for QA automation access

**DevOps Engineer owns:**
- CI pipeline configuration (GitHub Actions workflows for test jobs)
- Test environment provisioning (dev, test, dogfood, staging, prod AWS stacks)
- Device farm account setup and CI integration (Firebase Test Lab, BrowserStack)
- Golden test CI job configuration (pinned Linux Docker image)
- Test coverage reporting integration (Codecov/Coveralls)
- Sentry and CloudWatch monitoring setup that feeds into QA dashboards

### Collaboration boundaries

| Activity | QA | SWE | DevOps |
|----------|:--:|:---:|:------:|
| Write unit tests | Review | Author | -- |
| Write widget tests | Review | Author | -- |
| Write golden tests | Review diffs, approve | Author, regenerate | CI job config |
| Write integration tests | Author E2E flows | Author core flows | CI runner config |
| Write API tests (Postman) | Author | Review | CI Newman job |
| Write load tests (k6) | Author | Review | Staging env setup |
| Manual exploratory testing | Execute | Fix bugs | Provide test env |
| Bug triage | Lead | Participate | Participate |
| Release sign-off | Approve/block | Provide build | Deploy |
| Test environment requests | Request | -- | Fulfill |
| Device farm execution | Configure and run | -- | Account setup |

---

## 2. QA Environment and Tooling Setup

### 2.1 Test Frameworks and Tools

| Tool | Purpose | Owner |
|------|---------|-------|
| `flutter test` | Unit and widget tests | SWE authors, QA reviews |
| `integration_test` (Flutter) | On-device integration tests | SWE + QA co-author |
| `golden_toolkit` / `alchemist` | Visual regression golden files | SWE generates, QA reviews diffs |
| **Patrol** | Native mobile E2E (handles system dialogs, permissions) | QA authors |
| **Maestro** (backup) | YAML-driven mobile E2E, quick smoke tests | QA authors |
| **Playwright** | Web E2E testing | QA authors |
| **Postman + Newman** | GraphQL API testing collections, CI execution | QA authors |
| **k6** | Load and performance testing against AppSync/Lambda | QA authors |
| **Firebase Test Lab** | Android device farm (CI-integrated) | QA configures, DevOps provisions |
| **BrowserStack** | iOS device farm + cross-browser web testing | QA configures, DevOps provisions |
| **Sentry** | Crash reporting, session monitoring | DevOps sets up, QA monitors |
| **GitHub Issues** | Bug tracking with labels and templates | QA manages |

### 2.2 Device Matrix

**Physical devices (QA local lab):**

| Device | OS | Purpose |
|--------|----|---------|
| Pixel 7 (or equivalent mid-range) | Android 14 | Primary Android testing |
| Samsung Galaxy A-series | Android 12 | Low-end performance validation |
| iPhone 15 Pro | iOS 17 | Primary iOS testing |
| iPhone SE (3rd gen) | iOS 16 | Small screen, older iOS |
| iPad Air | iPadOS 17 | Tablet breakpoint (600-1024px) |

**Emulators/Simulators (local and CI):**

| Target | Configuration |
|--------|--------------|
| Android Emulator | Pixel 6 API 33, Pixel 4 API 30 |
| iOS Simulator | iPhone 15 Pro (iOS 17), iPhone SE (iOS 16) |
| Chrome | Desktop (1440x900), Tablet (1024x768), Mobile (375x812) |
| Firefox | Desktop (1440x900) -- web compatibility check |

**Device Farm (CI-integrated):**

| Service | Devices | Trigger |
|---------|---------|---------|
| Firebase Test Lab | Pixel 6 API 33, Pixel 4a API 30, Samsung Galaxy S22 | On merge to `main`, on `release/*` branches |
| BrowserStack | iPhone 14 Pro (iOS 16), iPhone 15 (iOS 17), iPad Pro 12.9 | On `release/*` branches |
| BrowserStack Browser | Chrome (latest), Safari (latest), Firefox (latest) | On `release/*` branches |

### 2.3 Test Environment Mapping

| Test Type | Environment | Backend |
|-----------|-------------|---------|
| Unit / Widget / Golden | Local + CI | No backend (mocked) |
| Integration tests (offline flows) | Local emulator + CI | Local Isar only (no AWS) |
| Integration tests (sync flows) | CI | Test environment (`api-test.alpha-app.com`) |
| API tests (Postman/Newman) | CI | Test environment |
| E2E tests (Patrol/Playwright) | CI + Device Farm | Staging environment (`api-stage.alpha-app.com`) |
| Load tests (k6) | CI (scheduled) | Staging environment |
| Manual exploratory | Local devices | Dogfood environment (`api-dogfood.alpha-app.com`) |
| Release verification | Local devices + Device Farm | Staging environment |

---

## 3. Test Plan by Sprint (12 Weeks, 6 Sprints)

### Sprint 1 (Weeks 1-2) -- Foundation

**SWE delivers:** Flutter project skeleton, Riverpod + GoRouter + Freezed + Isar integration, all data models defined, Isar schemas and local data sources, design system tokens and base components (MarkerIcon, GridCell, AlphaCard), ResponsiveScaffold with bottom nav/side rail, route definitions (stub screens). Backend: CDK scaffolding, DynamoDB table with GSIs, Cognito User Pool.

**QA test activities:**

| ID | Test Type | Description |
|----|-----------|-------------|
| S1-01 | Review | Review unit tests for Board, Task, Column, Marker model serialization/deserialization |
| S1-02 | Review | Review unit tests for task state machine transitions (OPEN to COMPLETE, OPEN to MIGRATED, OPEN to CANCELLED) |
| S1-03 | Review | Review widget tests for MarkerIcon rendering all 6 symbol variants |
| S1-04 | Manual | Verify project builds on Android, iOS, and Web without errors |
| S1-05 | Manual | Verify ResponsiveScaffold switches layout at breakpoints (under 600px, 600-1024px, over 1024px) |
| S1-06 | Manual | Verify GoRouter navigation between stub screens, back navigation |
| S1-07 | Manual | Verify Isar database creates and persists data across app restarts on all 3 platforms |
| S1-08 | Setup | Set up Postman workspace with initial GraphQL queries/mutations for Cognito auth endpoints |
| S1-09 | Setup | Configure Patrol project scaffolding for future E2E tests |
| S1-10 | Setup | Configure Playwright project scaffolding for web E2E tests |

**Platform coverage:**
- S1-04 through S1-07: Android emulator, iOS simulator, Chrome

**Entry criteria:** SWE has a green build on all platforms, all stub screens navigable.
**Exit criteria:** All manual checks pass. QA tooling scaffolding complete. No blocking build issues.

---

### Sprint 2 (Weeks 3-4) -- Core Grid MVP (Part 1)

**SWE delivers:** BoardListScreen (list, create, delete boards), BoardDetailScreen (matrix grid with fixed task column, horizontally scrollable marker columns, linked vertical scroll), tap-to-cycle markers, long-press marker picker.

**QA test activities:**

| ID | Test Type | Description |
|----|-----------|-------------|
| S2-01 | Review | Review widget tests for BoardListScreen (empty state, populated list, FAB behavior) |
| S2-02 | Review | Review widget tests for MarkerCell tap cycle (empty to DOT to CIRCLE to X to empty) |
| S2-03 | Review | Review widget tests for MarkerPickerPopup (long-press opens picker, all 6 symbols selectable) |
| S2-04 | Review | Review integration test for board lifecycle (create to verify columns to add tasks to verify grid) |
| S2-05 | Manual Exploratory | Grid rendering with various column counts: 7 (weekly), 12 (yearly), 31 (monthly) |
| S2-06 | Manual Exploratory | Horizontal scroll behavior -- verify frozen task column stays pinned |
| S2-07 | Manual Exploratory | Tap-to-cycle markers on touch (mobile) and mouse click (web) |
| S2-08 | Manual Exploratory | Long-press marker picker on mobile, right-click on web |
| S2-09 | Manual Exploratory | Grid performance: add 30+ tasks, verify no visible jank during scroll |
| S2-10 | Golden Review | Review golden file diffs for grid view (empty, populated, dense board) in light theme |
| S2-11 | E2E (Patrol) | Write: Create board, add 3 tasks, tap markers, verify persistence after app restart |
| S2-12 | E2E (Playwright) | Write: Create board on web, verify grid renders, tap markers with mouse |

**Platform coverage:**
- S2-05 through S2-09: Android (Pixel 7), iOS (iPhone 15 Pro), Chrome (1440x900), Chrome mobile emulation (375x812)
- S2-10: CI Linux runner (golden generation)
- S2-11: Android emulator, iOS simulator
- S2-12: Chrome

**Entry criteria:** Board list and grid screens functional with marker cycling.
**Exit criteria:** Marker cycling works correctly on all platforms. No scroll synchronization issues. Grid renders correctly with 31 columns. All E2E tests pass.

---

### Sprint 3 (Weeks 5-6) -- Core Grid MVP (Part 2)

**SWE delivers:** Swipe-to-complete/cancel, drag-to-reorder tasks, quick-add task via FAB, column management (add, rename, reorder, delete), task detail sheet (edit title, description, priority, deadline), InteractiveViewer for pinch-to-zoom on mobile. Backend: column and marker Lambda resolvers, board templates, dogfood environment deployed.

**QA test activities:**

| ID | Test Type | Description |
|----|-----------|-------------|
| S3-01 | Review | Review widget tests for Dismissible swipe-to-complete (right swipe) and swipe-to-cancel (left swipe) |
| S3-02 | Review | Review widget tests for ReorderableListView drag-to-reorder |
| S3-03 | Review | Review integration test for marker workflow and context shift |
| S3-04 | Manual Exploratory | Swipe gestures on Android and iOS -- swipe right completes, swipe left cancels |
| S3-05 | Manual Exploratory | Drag-to-reorder: edge cases (drag to top, to bottom, single task) |
| S3-06 | Manual Exploratory | Quick-add task via FAB: bottom sheet opens, text entry, submit |
| S3-07 | Manual Exploratory | Column management: add column, rename, reorder, delete with confirmation |
| S3-08 | Manual Exploratory | Task detail sheet: all fields editable, save persists |
| S3-09 | Manual Exploratory | Pinch-to-zoom on mobile (verify min/max scale, content remains interactive at zoom levels) |
| S3-10 | Manual Exploratory | Web: verify no InteractiveViewer, standard scroll behavior |
| S3-11 | Manual Exploratory | Undo snackbar after swipe-to-complete reverts task state |
| S3-12 | API (Postman) | Write: Full CRUD for columns (addColumn, updateColumn, removeColumn, reorderColumns) |
| S3-13 | API (Postman) | Write: Marker operations (setMarker, removeMarker, cycleMarker, shiftContext) |
| S3-14 | API (Postman) | Write: Auth validation -- all mutations reject unauthenticated requests (401) |
| S3-15 | E2E (Patrol) | Write: Complete task flow -- add task, cycle marker, swipe complete, verify strikethrough |
| S3-16 | E2E (Patrol) | Write: Reorder flow -- add 5 tasks, reorder, verify persistence |
| S3-17 | Golden Review | Review golden diffs for task detail sheet, column editor, all marker states |
| S3-18 | Dogfood | Begin daily use of dogfood builds, log issues in GitHub |

**Platform coverage:**
- S3-04 through S3-11: Android (Pixel 7, Galaxy A-series), iOS (iPhone 15 Pro, iPhone SE), Chrome, iPad
- S3-12 through S3-14: Newman against test environment
- S3-15, S3-16: Firebase Test Lab (Pixel 6 API 33), iOS Simulator

**Entry criteria:** Full grid interaction suite functional. Backend marker/column resolvers deployed to test.
**Exit criteria:** All swipe/drag/zoom gestures work on all target devices. API tests pass for all resolver endpoints. No data loss on reorder operations. Dogfood build installable and functional.

---

### Sprint 4 (Weeks 7-8) -- Templates, Migration, and Sync

**SWE delivers:** Board templates (Weekly, Monthly, GTD Contexts, etc.), Migration Wizard (end-of-period detection, task selection, confirm/cancel), board archiving, recurring task support (RRULE). Backend: migrateTasks mutation, AppSync subscriptions, syncBoard delta query, conflict resolution Lambda.

**QA test activities:**

| ID | Test Type | Description |
|----|-----------|-------------|
| S4-01 | Review | Review unit tests for RRULE parsing and next-occurrence calculation |
| S4-02 | Review | Review integration test for migration flow (create board, complete some tasks, migrate rest) |
| S4-03 | Manual Exploratory | Template picker: all 6 templates render, create board from each |
| S4-04 | Manual Exploratory | Monthly template: verify correct number of columns for selected month (28/29/30/31) |
| S4-05 | Manual Exploratory | Migration wizard: step-by-step flow (trigger, select target, pick tasks, confirm) |
| S4-06 | Manual Exploratory | Migration edge cases: all tasks complete (no prompt), single task, select all/deselect all |
| S4-07 | Manual Exploratory | Verify source board shows MIGRATED markers after migration |
| S4-08 | Manual Exploratory | Verify target board has migrated tasks with DOT markers |
| S4-09 | Manual Exploratory | Board archiving: archived boards hidden from default list, visible with toggle |
| S4-10 | Manual Exploratory | Recurring task: set recurrence rule, verify next occurrence created |
| S4-11 | API (Postman) | Write: migrateTasks mutation -- happy path, empty selection, invalid board IDs |
| S4-12 | API (Postman) | Write: syncBoard delta query -- returns only items modified after timestamp |
| S4-13 | API (Postman) | Write: Subscription setup verification (onBoardUpdated) |
| S4-14 | API (Postman) | Write: Cross-user authorization -- User A cannot access User B's boards |
| S4-15 | E2E (Patrol) | Write: Full migration flow -- create weekly board, add 10 tasks, complete 6, migrate 4 |
| S4-16 | E2E (Playwright) | Write: Template picker on web, create board from template, verify columns |
| S4-17 | Golden Review | Review golden diffs for migration wizard screens, template picker |

**Platform coverage:**
- S4-03 through S4-10: All devices in matrix
- S4-11 through S4-14: Newman against test environment
- S4-15: Firebase Test Lab, BrowserStack iOS
- S4-16: Chrome, Firefox

**Entry criteria:** Migration flow functional end-to-end. Backend sync resolvers deployed.
**Exit criteria:** Migration creates correct cross-board references. Recurring tasks generate correctly. No data integrity issues in migration transactions. Authorization prevents cross-user access.

---

### Sprint 5 (Weeks 9-10) -- Polish, Platform Optimization, and Sync

**SWE delivers:** Onboarding carousel, dark mode, keyboard shortcuts (web), right-click menus (web/desktop), hover states, haptic feedback (mobile), empty states, loading skeletons, undo support, performance profiling, collapsed view toggle. AWS Cognito auth screens, remote data sources (API client with Dio), sync engine (write-ahead queue, background isolate, delta pull, conflict resolution), sync status indicator.

**QA test activities:**

| ID | Test Type | Description |
|----|-----------|-------------|
| S5-01 | Manual Exploratory | Onboarding carousel: all pages render, interactive mini-grid demo works |
| S5-02 | Manual Exploratory | Dark mode: all screens, marker colors contrast correctly, no unreadable text |
| S5-03 | Manual Exploratory | Web keyboard shortcuts: N for new task, Cmd+Z undo, arrow keys navigate cells, Space to cycle marker |
| S5-04 | Manual Exploratory | Web right-click context menus on task rows: Edit, Delete, Migrate, Change Priority |
| S5-05 | Manual Exploratory | Hover states on MarkerCells (web only) |
| S5-06 | Manual Exploratory | Haptic feedback on marker tap (mobile only -- subjective check) |
| S5-07 | Manual Exploratory | Empty states shown for: empty board list, empty task list, no markers |
| S5-08 | Manual Exploratory | Loading skeletons shown during data fetch |
| S5-09 | Manual Exploratory | Auth flow: sign up with email, verify email, sign in, token refresh (background) |
| S5-10 | Manual Exploratory | Auth edge cases: invalid email format, weak password, wrong password, expired token |
| S5-11 | Manual Exploratory | Offline mode: toggle airplane mode, add tasks/markers, verify local persistence |
| S5-12 | Manual Exploratory | Reconnect sync: restore connectivity, verify sync queue flushes, data matches server |
| S5-13 | Manual Exploratory | Cross-device sync: create board on Device A, verify appears on Device B within 5s |
| S5-14 | Manual Exploratory | Conflict scenario: edit same task title on two devices offline, reconnect both, verify last-write-wins |
| S5-15 | Manual Exploratory | Marker conflict: set marker on same cell on two devices offline, reconnect, verify resolution |
| S5-16 | Manual Exploratory | Sync status indicator shows correct states: synced, syncing, offline, error |
| S5-17 | Golden Review | Review golden diffs for dark mode variants of all screens |
| S5-18 | Golden Review | Review golden diffs for onboarding carousel, empty states, loading skeletons |
| S5-19 | Performance | Grid initial render benchmark: measure time for 31-column, 50-task board on mid-range device |
| S5-20 | Performance | Scroll FPS: measure during rapid scroll of 50-task board on Pixel 7 and iPhone SE |
| S5-21 | Performance | Marker tap latency: measure time from tap to visual update |
| S5-22 | E2E (Patrol) | Write: Auth flow -- sign up, verify, sign in, view boards, sign out |
| S5-23 | E2E (Patrol) | Write: Offline/reconnect -- add tasks offline, reconnect, verify sync |
| S5-24 | E2E (Playwright) | Write: Web auth flow, keyboard shortcut navigation, dark mode toggle |
| S5-25 | API (Postman) | Write: Auth token refresh flow, multi-device session validation |

**Platform coverage:**
- S5-01 through S5-16: Full device matrix (all physical devices, emulators, all three web browsers)
- S5-13 through S5-15: Two physical devices simultaneously
- S5-19 through S5-21: Pixel 7, Galaxy A-series, iPhone 15 Pro, iPhone SE
- S5-22, S5-23: Firebase Test Lab, BrowserStack iOS
- S5-24: Chrome, Firefox, Safari

**Entry criteria:** Auth and sync fully integrated. Dark mode implemented. Keyboard shortcuts implemented.
**Exit criteria:** Auth flows work on all platforms. Offline-to-online sync resolves without data loss. Cross-device sync delivers within 5 seconds. Dark mode passes visual review. Performance benchmarks met (see Section 6).

---

### Sprint 6 (Weeks 11-12) -- Release Preparation

**SWE delivers:** Final bug fixes, performance optimization, error handling polish, app store submission preparation. Backend: staging and prod environments deployed, CloudWatch dashboards and alarms, AppSync caching tuned.

**QA test activities:**

| ID | Test Type | Description |
|----|-----------|-------------|
| S6-01 | Regression | Full regression pass: execute all E2E test suites on all platforms |
| S6-02 | Regression | Full API test suite execution against staging |
| S6-03 | Manual Exploratory | Edge cases: extremely long task titles (200+ chars), special characters, emoji in task titles |
| S6-04 | Manual Exploratory | Edge cases: max columns (31 for monthly), max tasks per board (100+), rapid tap on markers |
| S6-05 | Manual Exploratory | Error handling: network timeout during sync, server 500 response, malformed API response |
| S6-06 | Manual Exploratory | App lifecycle: background/foreground, memory pressure, kill and restore |
| S6-07 | Manual Exploratory | Accessibility: screen reader navigation (VoiceOver on iOS, TalkBack on Android), font scaling |
| S6-08 | Manual Exploratory | Deep links: `/board/:id` opens correct board from URL on web |
| S6-09 | Load Test (k6) | Execute full load test suite against staging (see Section 6) |
| S6-10 | Performance | Final performance benchmark pass on all target devices |
| S6-11 | Device Farm | Full E2E suite on Firebase Test Lab (3 Android devices) and BrowserStack (2 iOS devices) |
| S6-12 | Security | Verify no sensitive data in local storage (passwords, tokens in plaintext) |
| S6-13 | Security | Verify HTTPS enforcement on all API calls |
| S6-14 | Release Checklist | Execute full release QA checklist (Section 9) |
| S6-15 | Golden | Final golden baseline captured and approved for v1.0 |

**Platform coverage:**
- S6-01 through S6-08: Full device matrix
- S6-09: k6 against staging
- S6-11: Firebase Test Lab (Pixel 6, Pixel 4a, Samsung Galaxy S22), BrowserStack (iPhone 14 Pro, iPhone 15)

**Entry criteria:** All known P0/P1 bugs resolved. All features complete. Staging environment mirrors production.
**Exit criteria:** Release QA checklist fully passed (Section 9). No open P0 or P1 bugs. All automated test suites green. Load test thresholds met. Release sign-off granted.

---

## 4. Detailed Test Cases for Core Flows

### 4a. Board CRUD

| ID | Precondition | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| B-001 | User logged in, no boards | 1. Tap FAB on board list. 2. Enter name "Week of March 9". 3. Select Weekly template. 4. Tap Create. | Board appears in list with 7 day columns (Mon-Sun). Board detail shows empty grid with correct column headers. | P0 |
| B-002 | User logged in, no boards | 1. Tap FAB. 2. Select "GTD Contexts" template. 3. Tap Create. | Board created with columns: Calendar, Email, Phone, Projects, Thinking, Waiting For. | P0 |
| B-003 | User logged in, no boards | 1. Tap FAB. 2. Select Monthly template. 3. Select month with 31 days. 4. Create. | Board has exactly 31 columns labeled 1-31. | P1 |
| B-004 | User logged in, no boards | 1. Tap FAB. 2. Select Monthly template. 3. Select February (non-leap year). 4. Create. | Board has exactly 28 columns. | P1 |
| B-005 | Board "Week 10" exists | 1. Open board list. 2. Tap board "Week 10". | Board detail screen opens. Grid renders with all columns and tasks. | P0 |
| B-006 | Board "Week 10" exists | 1. Open board overflow menu. 2. Tap Edit. 3. Change name to "Week 10 Updated". 4. Save. | Board list and detail reflect new name. | P1 |
| B-007 | Board "Week 10" exists with 5 tasks | 1. Open board overflow menu. 2. Tap Archive. 3. Confirm. | Board disappears from default list. Toggling "Show Archived" reveals it. | P1 |
| B-008 | Archived board exists | 1. Toggle "Show Archived". 2. Open archived board. 3. Unarchive. | Board reappears in default list. | P2 |
| B-009 | Board "Week 10" exists, no tasks | 1. Open board overflow menu. 2. Tap Delete. 3. Confirm. | Board removed from list. Not recoverable. | P1 |
| B-010 | Board with tasks and markers exists | 1. Delete board. | All associated tasks, columns, and markers are deleted. No orphaned data. | P1 |

### 4b. Marker Grid Interaction

| ID | Precondition | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| M-001 | Board with tasks and columns, cell is empty | 1. Tap empty cell at Task 1 x Monday. | DOT marker appears in cell. | P0 |
| M-002 | Cell shows DOT marker | 1. Tap cell. | Marker changes to CIRCLE (started). | P0 |
| M-003 | Cell shows CIRCLE marker | 1. Tap cell. | Marker changes to X (done). | P0 |
| M-004 | Cell shows X marker | 1. Tap cell. | Cell returns to empty (no marker). | P0 |
| M-005 | Cell is empty | 1. Long-press cell (mobile) or right-click (web). | Marker picker popup opens showing: DOT, CIRCLE, X, STAR, TILDE, MIGRATED. | P0 |
| M-006 | Marker picker is open | 1. Select STAR from picker. | Cell shows STAR marker. Picker dismisses. | P0 |
| M-007 | Marker picker is open | 1. Select TILDE from picker. | Cell shows TILDE marker (recurring indicator). | P1 |
| M-008 | DOT marker in "Email" column for Task 1 | 1. Tap "Email" cell (cycles to X). 2. Long-press "Waiting For" cell. 3. Select DOT. | "Email" shows X, "Waiting For" shows DOT. Context shift complete. | P0 |
| M-009 | Multiple cells have markers | 1. Tap a cell rapidly 10 times in succession. | Marker cycles correctly through all states without skipping or doubling. No crash. | P1 |
| M-010 | Board with markers | 1. Close app. 2. Reopen app. 3. Navigate to board. | All marker states preserved exactly as set. | P0 |
| M-011 | Cell is empty (mobile) | 1. Tap cell. | Haptic feedback (light impact) is felt on tap. Ripple animation visible. | P2 |
| M-012 | Board with markers (web) | 1. Hover over a MarkerCell. | Subtle highlight appears on hover. | P2 |

### 4c. Task Management

| ID | Precondition | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| T-001 | Board open with at least 1 column | 1. Tap FAB. 2. Enter "Send proposal". 3. Submit. | Task appears at bottom of task list. Position is last. | P0 |
| T-002 | Board with tasks A, B, C, D, E | 1. Long-press task C. 2. Drag to position 1 (above A). 3. Release. | Order becomes C, A, B, D, E. Position values updated. | P0 |
| T-003 | Board with tasks, task "Buy milk" is OPEN | 1. Swipe "Buy milk" row to the right. | Strikethrough animation plays across the row. Task state changes to COMPLETE. `completedAt` timestamp is set. Undo snackbar appears. | P0 |
| T-004 | Undo snackbar visible after completing task | 1. Tap "Undo" on snackbar. | Task reverts to OPEN. Strikethrough removed. `completedAt` cleared. | P1 |
| T-005 | Board with tasks, task "Research" is OPEN | 1. Swipe "Research" row to the left. | Task state changes to CANCELLED. Row visually struck through or dimmed. | P0 |
| T-006 | Task is already COMPLETE | 1. Attempt to swipe right. | No-op. Task remains COMPLETE. | P2 |
| T-007 | Board open | 1. Tap on task title "Send proposal". | Task detail sheet opens showing title, description, priority, deadline fields. | P1 |
| T-008 | Task detail sheet open | 1. Change title to "Send proposal v2". 2. Set priority to HIGH. 3. Set deadline to March 20. 4. Save. | All changes persist. Board view reflects updated title. | P1 |
| T-009 | Board with 50 tasks | 1. Scroll vertically through task list. | Smooth scrolling at 60fps. No dropped frames on mid-range device. | P1 |
| T-010 | Board open | 1. Tap FAB. 2. Submit with empty title. | Validation error: "Task title is required". Task not created. | P1 |

### 4d. Migration Flow

| ID | Precondition | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| MG-001 | Weekly board with period ended, 3 OPEN tasks, 2 COMPLETE tasks | 1. Open board. | Banner appears: "This period has ended. Migrate incomplete tasks?" | P0 |
| MG-002 | Migration banner visible | 1. Tap "Migrate". 2. Select "Create new weekly board" as target. | Migration wizard opens at task selection step. | P0 |
| MG-003 | Migration wizard at task selection | 1. Verify all OPEN and IN_PROGRESS tasks are pre-selected. 2. Verify COMPLETE tasks are not shown. | Checklist shows only incomplete tasks, all checked by default. | P0 |
| MG-004 | 3 tasks selected in migration wizard | 1. Deselect 1 task. 2. Tap "Migrate 2 tasks". 3. Confirm. | Source board: 2 migrated tasks show MIGRATED state and `>` marker. 1 deselected task unchanged. Target board: 2 new tasks with DOT markers appear. | P0 |
| MG-005 | Migration complete | 1. Open source board. 2. Check migrated tasks. | Migrated tasks show `>` symbol. State is MIGRATED. Tasks are visually differentiated (grayed). | P0 |
| MG-006 | Migration complete | 1. Open target board. | Migrated tasks appear with OPEN state. `migratedFromTaskId` and `migratedFromBoardId` fields are set. | P0 |
| MG-007 | Weekly board with period ended, ALL tasks COMPLETE | 1. Open board. | No migration banner appears. | P1 |
| MG-008 | Migration wizard open | 1. Tap "Select All". | All tasks selected. | P1 |
| MG-009 | Migration wizard open | 1. Tap "Deselect All". 2. Tap "Migrate 0 tasks". | Migrate button is disabled when 0 tasks selected. | P1 |
| MG-010 | Migration wizard open | 1. Tap Cancel/Back. | Wizard dismisses. No changes to any board. | P1 |
| MG-011 | Board with 50 incomplete tasks | 1. Trigger migration. 2. Select all. 3. Confirm. | All 50 tasks migrated successfully. No timeouts. Transaction completes atomically. | P1 |

### 4e. Offline/Sync

| ID | Precondition | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| OF-001 | User logged in, online, board exists | 1. Enable airplane mode. 2. Add new task "Offline Task 1". 3. Set DOT marker on Monday column. | Task and marker created locally. Sync indicator shows "Offline". | P0 |
| OF-002 | Offline, tasks and markers created offline | 1. Disable airplane mode. | Sync indicator changes to "Syncing" then "Synced". | P0 |
| OF-003 | After reconnection sync | 1. Log in on Device B. 2. Open same board. | "Offline Task 1" appears with DOT marker on Monday. | P0 |
| OF-004 | Two devices online viewing same board | 1. On Device A, add task "Cross Device". 2. Wait 5 seconds. 3. Check Device B. | Task appears on Device B via subscription within 5 seconds. | P0 |
| OF-005 | Two devices offline | 1. On Device A (offline): add task "From A". 2. On Device B (offline): add task "From B". 3. Reconnect both. | Both tasks appear on both devices after sync. No data loss. | P0 |
| OF-006 | Two devices offline | 1. On Device A: set marker on Task 1 x Monday to DOT. 2. On Device B: set same marker to STAR. 3. Reconnect both. | Last-write-wins: the device that reconnected last determines the marker. No crash or corrupt state. | P1 |
| OF-007 | Two devices offline | 1. On Device A: change task title to "Title A". 2. On Device B: change same task priority to HIGH. 3. Reconnect both. | Field-level merge: title is "Title A" AND priority is HIGH. | P1 |
| OF-008 | User offline for extended period (1+ hour) | 1. Make 20+ changes offline (tasks, markers, completions). 2. Reconnect. | All 20+ changes sync successfully. Sync queue drains completely. | P1 |
| OF-009 | User online | 1. Start rapid marker toggling (10 taps in 5 seconds). | All marker changes sync. No queuing backlog. Final state matches both locally and server-side. | P1 |
| OF-010 | Network drops mid-sync | 1. Start sync with queued changes. 2. Kill network mid-transfer. 3. Restore network. | Sync resumes from where it left off. No duplicate entries. Idempotent operations. | P1 |

### 4f. Auth Flows

| ID | Precondition | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| A-001 | App installed, no account | 1. Tap "Sign Up". 2. Enter email, password (8+ chars, mixed case, number). 3. Submit. | Verification email sent. User prompted to enter verification code. | P0 |
| A-002 | Verification code received | 1. Enter correct code. 2. Submit. | Account verified. User redirected to onboarding or board list. | P0 |
| A-003 | Account exists | 1. Tap "Sign In". 2. Enter correct email and password. 3. Submit. | User logged in. Board list loads. Access token, refresh token, and ID token stored securely. | P0 |
| A-004 | Sign-in screen | 1. Enter correct email. 2. Enter wrong password. 3. Submit. | Error message: "Incorrect email or password." No account lockout on first attempt. | P0 |
| A-005 | Sign-in screen | 1. Enter nonexistent email. 2. Enter any password. 3. Submit. | Same generic error: "Incorrect email or password." (No user enumeration.) | P1 |
| A-006 | User signed in, access token expired | 1. Wait for token expiry (1 hour) or simulate. | App automatically refreshes token using refresh token. No interruption to user. | P0 |
| A-007 | User signed in on Device A | 1. Sign in on Device B with same credentials. | Both devices remain signed in. Cognito supports concurrent sessions. | P0 |
| A-008 | User signed in | 1. Tap "Sign Out". | User returned to sign-in screen. Tokens cleared. Local data retained (offline access). | P1 |
| A-009 | Sign-up screen | 1. Enter invalid email format (e.g., "notanemail"). 2. Submit. | Validation error: "Please enter a valid email address." | P1 |
| A-010 | Sign-up screen | 1. Enter password "1234567" (too short, no mixed case). 2. Submit. | Validation error indicating password requirements. | P1 |

---

## 5. Visual/Golden Test Strategy

### 5.1 Screens and Variants to Capture

| Screen | Variants | Count |
|--------|----------|-------|
| Board list | Empty, 3 boards, 10 boards (scrollable) | 3 |
| Board grid (matrix) | Empty (0 tasks), populated (7 cols / 10 tasks), dense (31 cols / 50 tasks) | 3 |
| Marker cell states | All 6 symbols + empty = 7 states | 1 composite |
| Migration wizard | Step 1 (trigger banner), Step 3 (task selection with 3 selected), Step 3 (0 selected) | 3 |
| Board creation form | Initial state, validation error state | 2 |
| Template picker | Gallery view with all 6 templates | 1 |
| Task detail sheet | Full fields, minimal fields | 2 |
| Column editor | 5 custom columns | 1 |
| Settings screen | Default state | 1 |
| Onboarding carousel | Each page (3-4 pages) | 4 |
| Empty states | No boards, no tasks | 2 |
| Loading skeletons | Board list loading, board grid loading | 2 |
| Auth screens | Sign in, sign up, verification | 3 |

**Total screen variants:** approximately 28

### 5.2 Breakpoints

Each variant is captured at 5 breakpoints:

| Breakpoint | Resolution | Target |
|------------|-----------|--------|
| Phone portrait | 375x812 | iPhone SE / small Android |
| Phone landscape | 812x375 | Landscape phone |
| Tablet | 1024x768 | iPad Air |
| Web desktop | 1440x900 | Standard desktop |
| Web narrow | 768x1024 | Narrow desktop / portrait tablet |

### 5.3 Theme Variants

Each screen-breakpoint combination is captured in both **light** and **dark** themes.

**Total golden files:** 28 variants x 5 breakpoints x 2 themes = **280 golden files**

### 5.4 Golden File Management Workflow

1. **Generation:** Goldens are generated ONLY on CI using a pinned Linux Docker image (`ubuntu-22.04` with a specific Flutter SDK version). Locally generated goldens are never committed (`.gitignore` the local goldens output directory).

2. **Storage:** Golden files stored at `test/goldens/` organized as:
   ```
   test/goldens/
     board_list/
       empty_phone_portrait_light.png
       empty_phone_portrait_dark.png
       ...
     board_grid/
       populated_tablet_light.png
       ...
   ```

3. **Diff tolerance:** 0.5% pixel-diff tolerance to accommodate anti-aliasing differences.

4. **Update workflow:**
   - SWE makes UI change.
   - CI golden test job detects diff, posts visual comparison images as a PR comment (using `alchemist` or a custom GitHub Action).
   - QA reviews the visual diff comment on the PR.
   - If approved: QA comments "goldens approved" (or applies a GitHub label `goldens-approved`).
   - SWE runs `flutter test --update-goldens --tags=golden` on CI via a manual workflow dispatch, commits updated goldens.
   - If rejected: QA comments with specific feedback, SWE iterates.

5. **Approval authority:** QA Engineer has sole approval authority for golden file changes. No golden file updates may be merged without QA approval (enforced via the `goldens-approved` label as a branch protection required check, or a manual review gate).

---

## 6. Performance Testing Plan

### 6.1 Client-Side Benchmarks

| Metric | Target | Measurement Method | Device |
|--------|--------|-------------------|--------|
| Grid initial render (7 cols, 10 tasks) | Under 300ms | `Timeline.startSync`/`stopSync` in integration test | Pixel 7, iPhone 15 Pro |
| Grid initial render (31 cols, 50 tasks) | Under 500ms | Same as above | Pixel 7, iPhone 15 Pro |
| Grid initial render (31 cols, 50 tasks) | Under 800ms | Same as above | Galaxy A-series (low-end) |
| Vertical scroll FPS (50 tasks) | 60fps sustained (no frame drops below 55fps) | Flutter DevTools performance overlay | Pixel 7, Galaxy A-series |
| Horizontal scroll FPS (31 cols) | 60fps sustained | Same as above | Pixel 7, Galaxy A-series |
| Marker tap to visual update | Under 100ms | Stopwatch in integration test | All physical devices |
| Swipe-to-complete animation | Under 300ms end-to-end | Visual inspection + profiling | All physical devices |
| App cold start to board list | Under 2 seconds | `Timeline` profiling | Pixel 7, iPhone 15 Pro |
| App cold start to board list | Under 3 seconds | Same | Galaxy A-series |

**When to run:** Every sprint during integration testing phase. Automated as part of CI integration test suite on merge to `main`.

**Tools:** Flutter DevTools (performance overlay, timeline), `integration_test` with `Timeline` API, custom `Stopwatch` instrumentation in test harness.

### 6.2 API/Backend Performance (k6)

| Scenario | Virtual Users | Duration | Success Criteria |
|----------|--------------|----------|-----------------|
| Steady-state board viewing | 100 concurrent | 5 minutes | p95 under 100ms for `getBoard` query, 0% error rate |
| Marker toggling storm | 100 concurrent, 1 `cycleMarker` mutation per 2s | 5 minutes | p95 under 200ms, 0% error rate |
| Board creation burst | 50 simultaneous `createBoard` mutations | Single burst | All succeed within 5 seconds, 0% duplicates |
| Migration spike | 30 concurrent `migrateTasks` (20 tasks each) | 2 minutes | All complete, p95 under 3s, data integrity verified |
| Read-heavy (board list + board detail) | 500 concurrent | 10 minutes | p95 under 100ms for reads, 0% DynamoDB throttling |
| Delta sync under load | 200 concurrent `syncBoard` calls | 5 minutes | p95 under 500ms |

**When to run:** Sprint 6 (release preparation) against staging environment. Repeated before every production release.

**k6 script location:** `test/load/` directory (QA authors, SWE reviews).

**Thresholds enforced in k6:**
```
thresholds: {
  http_req_duration: ['p(95)<200', 'p(99)<500'],
  http_req_failed: ['rate<0.01'],
}
```

### 6.3 Performance Regression Detection

- Benchmark results stored as JSON artifacts in CI.
- Sprint-over-sprint comparison: if any metric degrades by more than 20%, a P1 performance bug is filed automatically.
- Performance dashboard (simple markdown table updated in the repo or a Grafana board if available).

---

## 7. Bug Reporting and Triage

### 7.1 Severity Definitions

| Severity | Definition | Examples | SLA |
|----------|-----------|----------|-----|
| **P0 -- Blocker** | App crashes, data loss, security vulnerability, complete feature non-functional | Crash on marker tap, tasks disappearing after sync, auth bypass | Fix within 24 hours, hotfix release |
| **P1 -- Critical** | Major feature broken but workaround exists, significant data integrity issue | Migration creates duplicate tasks, offline sync loses 1 of 20 changes, swipe-to-complete doesn't persist | Fix within current sprint |
| **P2 -- Major** | Feature partially broken, visual defect affecting usability | Wrong marker symbol displayed, column reorder not persisting, dark mode text unreadable on one screen | Fix within next sprint |
| **P3 -- Minor** | Cosmetic issue, minor UX friction, edge case | Pixel misalignment on one breakpoint, hover state missing on one component, haptic feedback too strong | Backlog, fix when convenient |

### 7.2 Bug Report Template

```markdown
## Bug Report

**ID:** BUG-[auto-increment]
**Title:** [One-line summary]
**Severity:** P0 / P1 / P2 / P3
**Platform:** Android / iOS / Web / All
**Device:** [e.g., Pixel 7, Android 14]
**App Version:** [e.g., 1.0.0+42]
**Environment:** Dev / Dogfood / Staging / Prod

### Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Expected Result
[What should happen]

### Actual Result
[What actually happens]

### Screenshots / Video
[Attach]

### Logs
[Relevant Sentry link, console output, or crash stack trace]

### Reproducibility
Always / Intermittent (X of Y attempts) / Once

### Additional Context
[Related test case ID, related PR, etc.]
```

### 7.3 Triage Process

1. **Daily triage (15 min):** QA leads a daily bug triage with the Software Engineer. Review all new bugs filed in the last 24 hours.
2. **Assign severity:** QA assigns severity based on definitions above.
3. **Assign owner:** SWE picks up P0/P1 immediately. P2 goes into sprint backlog. P3 goes into general backlog.
4. **Verify fix:** When SWE marks a bug as fixed, QA verifies the fix on the target platform(s) before closing.
5. **Regression test:** Every P0 and P1 bug fix must have an accompanying automated test (unit, widget, or E2E) that would catch the regression. QA verifies the regression test exists before closing.

### 7.4 Regression Test Policy

- Every P0/P1 bug fix MUST have an automated regression test.
- Every P2 bug fix SHOULD have an automated regression test (QA's discretion based on risk).
- The regression test is reviewed by QA and must reproduce the original bug scenario.
- A `regression` tag is applied to these tests for tracking purposes.

---

## 8. Collaboration Points

### 8.1 With Software Engineer

| Touchpoint | Frequency | Details |
|------------|-----------|---------|
| Sprint planning | Every 2 weeks | QA provides testing effort estimates, identifies testability requirements for upcoming stories |
| Build handoff | End of each story | SWE deploys to dogfood, notifies QA with build number and changelog |
| Test hook requests | As needed | QA requests semantic labels (`Semantics(label: 'marker_cell_task1_monday')`), `Key` values for specific widgets, and `ValueKey` identifiers for Patrol/Playwright selectors |
| Testability review | Per story | QA reviews story acceptance criteria BEFORE development starts, adds test-specific requirements (e.g., "sync status indicator must expose state via Semantics for automation") |
| Bug fix verification | Per bug | SWE notifies QA when fix is in dogfood build. QA verifies and closes or reopens. |
| Test code review | Per PR | SWE reviews QA's E2E/API test PRs for code quality. QA reviews SWE's unit/widget test PRs for coverage gaps. |
| Pair debugging | As needed | For intermittent bugs or sync-related issues, QA and SWE pair to reproduce and diagnose |

**Test hook requirements document:** QA maintains a running list of required test hooks (widget keys, semantic labels, test-only endpoints) that SWE implements. This list is reviewed at each sprint planning.

### 8.2 With Product Designer

| Touchpoint | Frequency | Details |
|------------|-----------|---------|
| Design review | Per story | QA compares implemented UI against Figma designs, pixel-level where golden tests apply |
| Golden file approval | Per PR with UI changes | QA reviews visual diffs and confirms they match the design intent |
| Accessibility review | Per sprint | QA checks color contrast ratios (WCAG AA minimum), touch target sizes (44x44pt minimum), screen reader labels, font scaling (up to 200%) |
| Responsive layout review | Per new screen | QA verifies all breakpoints match the responsive design spec (under 600px, 600-1024px, over 1024px) |
| Dark mode validation | Per sprint (from Sprint 5) | QA verifies dark mode colors match design tokens, no contrast issues |

### 8.3 With DevOps Engineer

| Touchpoint | Frequency | Details |
|------------|-----------|---------|
| Test environment provisioning | Sprint 1 (initial), then as needed | QA requests dogfood/staging environments, specific DynamoDB seed data, Cognito test users |
| CI test job configuration | Sprint 1-2 (initial), then per new test type | QA specifies: which tests run on PR vs merge vs release, device farm configuration, timeout settings, artifact collection |
| Device farm setup | Sprint 2 | QA provides device/OS matrix; DevOps configures Firebase Test Lab and BrowserStack integration in GitHub Actions |
| Golden test CI job | Sprint 2 | DevOps sets up pinned Linux Docker image for deterministic golden generation |
| Load test infrastructure | Sprint 5-6 | DevOps ensures k6 has network access to staging AppSync endpoint, provides CloudWatch read access for QA to monitor backend metrics during load tests |
| Test data cleanup | As needed | QA requests cleanup Lambda or script to purge test users/data from test/staging environments |
| Flaky test investigation | As needed | QA reports flaky tests; DevOps investigates CI runner stability, resource constraints, timing issues |

---

## 9. Release QA Checklist

This checklist must be fully completed and signed off by QA before any production release.

### Pre-Release Verification

- [ ] All P0 and P1 bugs resolved and verified
- [ ] No open P0 or P1 bugs in the release scope
- [ ] All P2 bugs reviewed -- either fixed, deferred with justification, or accepted as known issues

### Automated Test Gates

- [ ] Unit tests: 100% pass rate (Flutter and backend)
- [ ] Widget tests: 100% pass rate
- [ ] Golden tests: 100% pass rate (all diffs reviewed and approved)
- [ ] Integration tests: 100% pass rate on all platforms (Android, iOS, Web)
- [ ] E2E tests (Patrol): 100% pass rate on Firebase Test Lab and BrowserStack
- [ ] E2E tests (Playwright): 100% pass rate on Chrome, Firefox, Safari
- [ ] API tests (Newman): 100% pass rate against staging
- [ ] Code coverage: meets minimum thresholds (80% Flutter overall, 85% backend overall)
- [ ] `flutter analyze`: zero error-level issues
- [ ] Contract tests: pass (frontend DTOs match backend GraphQL schema)

### Performance Verification

- [ ] Grid render under 500ms on mid-range device (31 cols, 50 tasks)
- [ ] Scroll FPS at 60fps on mid-range device
- [ ] Marker tap latency under 100ms
- [ ] App cold start under 2 seconds on mid-range device
- [ ] k6 load tests pass all thresholds against staging
- [ ] No performance regression exceeding 20% from previous release

### Platform-Specific Checks

- [ ] Android: tested on at least 2 device types (high-end + mid-range), 2 OS versions
- [ ] iOS: tested on at least 2 device types (latest iPhone + iPhone SE), 2 OS versions
- [ ] Web: tested on Chrome (latest), Firefox (latest), Safari (latest)
- [ ] Tablet: tested on iPad (or Android tablet equivalent)
- [ ] Responsive breakpoints verified: phone, tablet, desktop

### Feature Verification (Manual)

- [ ] Board CRUD: create, edit, archive, delete
- [ ] Marker cycling: tap cycle works on all platforms
- [ ] Long-press / right-click marker picker works
- [ ] Context shifting: marker moves between columns correctly
- [ ] Task add, reorder (drag), swipe-complete, swipe-cancel
- [ ] Migration flow: trigger, select, confirm, verify cross-board
- [ ] Template picker: all templates create correct boards
- [ ] Offline mode: works without connectivity, data persists
- [ ] Reconnection sync: all offline changes sync after reconnect
- [ ] Cross-device sync: changes propagate within 5 seconds
- [ ] Auth: sign up, verify email, sign in, token refresh, sign out
- [ ] Dark mode: all screens render correctly
- [ ] Onboarding: carousel displays and functions

### Security Checks

- [ ] No secrets in local storage (plaintext passwords, API keys)
- [ ] All API communication over HTTPS
- [ ] Auth tokens stored securely (Keychain on iOS, Keystore on Android)
- [ ] Cross-user data isolation verified (User A cannot access User B's boards)
- [ ] Dependency vulnerability scan: no high/critical vulnerabilities

### Deployment Readiness

- [ ] Release build tested (not debug build)
- [ ] Version number and build number correct in `pubspec.yaml`
- [ ] Changelog/release notes written
- [ ] App store metadata updated (screenshots, description) if applicable
- [ ] Rollback plan documented and verified

**Sign-off:**
- QA Engineer: _____________ Date: _____________
- Software Engineer: _____________ Date: _____________

---

## 10. Metrics and Reporting

### 10.1 QA Metrics to Track

| Metric | Definition | Target | Frequency |
|--------|-----------|--------|-----------|
| **Test case count** | Total automated tests by type (unit, widget, golden, integration, E2E, API, load) | Growing with features | Per sprint |
| **Test pass rate** | Percentage of tests passing on CI (per type) | 100% for unit/widget, over 98% for E2E | Per CI run |
| **Flaky test rate** | Tests failing on CI without code changes / total tests | Under 2% | Monthly |
| **Code coverage** (Flutter) | Line coverage from `flutter test --coverage` | Over 80% overall, over 95% for models | Per PR |
| **Code coverage** (Backend) | Line coverage from Jest | Over 85% overall | Per PR |
| **Bugs found per sprint** | Count of new bugs filed, by severity | Trending down over time | Per sprint |
| **Bug fix time** | Median time from bug filed to fix verified | P0: under 24h, P1: within sprint, P2: within 2 sprints | Per sprint |
| **Bug escape rate** | Bugs found in production / total bugs found | Under 5% | Per release |
| **Regression count** | Previously fixed bugs that reappear | 0 (target) | Per sprint |
| **CI execution time** | Time from PR push to all checks green | Under 10 min for PR checks, under 30 min for full pipeline | Per sprint |
| **Device farm pass rate** | E2E tests passing on Firebase Test Lab and BrowserStack | Over 95% | Per release |
| **Golden test approval time** | Time from golden diff posted to QA approval | Under 4 hours | Per PR with UI changes |
| **Release QA cycle time** | Time from build candidate to release sign-off | Under 2 business days | Per release |

### 10.2 Reporting Cadence

| Report | Audience | Frequency | Format |
|--------|----------|-----------|--------|
| **Sprint QA Summary** | Full team | End of each sprint | Markdown in sprint retrospective. Includes: tests added, bugs found/fixed/open by severity, coverage delta, flaky test status, performance benchmark results. |
| **Release Quality Report** | Full team + stakeholders | Per release | Standalone document. Includes: release checklist status, all metrics, known issues, risk assessment. |
| **Weekly Quality Pulse** | Software Engineer + DevOps | Weekly (async) | Short Slack/Teams message: open bugs by severity, CI health, any blockers. |
| **Monthly Quality Trends** | Full team | Monthly | Dashboard or markdown with trend charts: bugs over time, coverage trend, flaky test trend, performance regression trend. |

### 10.3 Quality Dashboard

QA maintains a quality dashboard (GitHub Project board or equivalent) with the following columns:

- **New** -- Bugs awaiting triage
- **Triaged** -- Severity assigned, awaiting SWE pickup
- **In Progress** -- SWE working on fix
- **Ready to Verify** -- Fix deployed to dogfood/staging, awaiting QA verification
- **Verified/Closed** -- Fix confirmed, regression test exists

Bug count by severity is visible at a glance. This is the source of truth for quality status.