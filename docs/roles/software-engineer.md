# AlPHA — Senior Software Engineer Implementation Plan

## 1. Role & Responsibilities

### What This Role Owns

- **All Flutter application code**: widgets, state management, data layer, navigation, theming, and platform-specific adaptations (Android, iOS, Web).
- **Local persistence layer**: Isar schema definitions, DAOs, repository implementations.
- **Sync engine**: Write-ahead queue, conflict resolution logic on the client side, background isolate for sync operations.
- **AppSync GraphQL integration**: Query/mutation/subscription client code, offline cache configuration, DTO mappers.
- **Unit and widget tests**: Minimum 80% coverage on business logic (use cases, repositories, sync engine), minimum 70% on widget layer.
- **Build configuration**: Flavor/scheme definitions for dev, dogfood, staging, prod. Environment variable injection via `--dart-define` or `.env` files.
- **Performance profiling**: Ensuring 60fps on the board matrix grid with synthetic stress data (100 tasks x 31 columns).
- **Code reviews**: Reviewing all PRs touching Flutter code; approving before merge.

### What Gets Handed Off

| Handoff To | What | When |
|---|---|---|
| **Product Designer** | Receives design specs (Figma), component measurements, interaction specs. Requests clarification on ambiguous states. | Before each sprint's implementation begins |
| **QA Engineer** | Delivers testable builds with semantic test IDs (`Key('marker_cell_$taskId_$colId')`), documented test hooks, and acceptance criteria per feature. | End of each sprint |
| **DevOps Engineer** | Receives build variant requirements (bundle IDs, signing configs, flavor names). Maintains CI/CD pipeline definitions collaboratively. | Sprint 1 setup, then as needed |

---

## 2. Development Environment Setup

### Required Tools & Versions

| Tool | Version | Notes |
|---|---|---|
| **Flutter SDK** | 3.24.x (stable channel) | Pin via `.fvm` or `asdf` for team consistency |
| **Dart SDK** | Bundled with Flutter (3.5.x) | Do not install separately |
| **IDE** | VS Code with Flutter/Dart extensions, OR Android Studio Hedgehog+ | VS Code recommended for lighter weight |
| **Xcode** | 16.x | Required for iOS builds |
| **Android Studio / SDK** | API 34 target, minimum API 24 | `sdkmanager` for emulator images |
| **Chrome** | Latest stable | For Flutter Web development |
| **Node.js** | 20 LTS | For CDK infrastructure (if touching backend locally) |
| **AWS CLI** | v2 | For local AWS service interaction |
| **DynamoDB Local** | Latest Docker image (`amazon/dynamodb-local`) | Offline backend development |
| **Git** | 2.40+ | With conventional commit hooks |

### IDE Configuration (VS Code)

**Required Extensions:**
- `Dart-Code.dart-code`
- `Dart-Code.flutter`
- `usernamehw.errorlens`
- `gruntfuggly.todo-tree`
- `streetsidesoftware.code-spell-checker`

**Workspace Settings** (`.vscode/settings.json`):
- `dart.lineLength`: 100
- `editor.formatOnSave`: true
- `dart.flutterSdkPath`: pointed at FVM symlink
- `dart.analysisExcludedFolders`: `["**/*.g.dart", "**/*.freezed.dart"]`

### Local Development Stack

1. **Flutter app**: `flutter run -d chrome` (web), `flutter run` (connected device/emulator)
2. **DynamoDB Local**: `docker run -p 8000:8000 amazon/dynamodb-local`
3. **AppSync mock**: Use `amplify mock api` or a local GraphQL server
4. **Build runners**: `dart run build_runner watch --delete-conflicting-outputs`

### Initial Project Bootstrap

```bash
flutter create --org com.alastairdrong --project-name alpha --platforms android,ios,web alpha_app
cd alpha_app
flutter pub add flutter_riverpod riverpod_annotation go_router freezed_annotation json_annotation isar isar_flutter_libs dio connectivity_plus linked_scroll_controller uuid intl flutter_slidable path_provider
flutter pub add --dev freezed build_runner json_serializable riverpod_generator custom_lint riverpod_lint isar_generator flutter_lints
```

---

## 3. Sprint-by-Sprint Breakdown (12 Weeks, 6 Sprints)

### Sprint 1 (Weeks 1-2): Foundation & Skeleton

**Features/Modules:**
- Flutter project scaffolding with the full `lib/` folder structure
- All Freezed data models: `Board`, `BoardColumn`, `Task`, `Marker` with enums
- Isar schema definitions and local data source implementations
- Repository interfaces and local-only implementations
- GoRouter route definitions with stub screens for all 8 routes
- `ResponsiveScaffold` with bottom nav (mobile) / side rail (tablet) / drawer (web)
- Design system foundation: `AppColors`, `AppTypography`, `MarkerIcon`, `GridCell`, `AlphaCard`
- Riverpod provider scaffolding

**Acceptance Criteria:**
- App compiles and runs on Android emulator, iOS simulator, and Chrome
- Navigation between all stub screens works with correct URL paths
- A `Board` can be created, read, updated, and deleted from Isar
- `ResponsiveScaffold` switches layout at 600px and 1024px breakpoints
- All Freezed models serialize/deserialize correctly (unit tests pass)
- `MarkerIcon` renders all 6 symbol variants

**Dependencies:**
- Product Designer: finalized color palette, typography scale, and app icon by end of Sprint 1
- DevOps: CI pipeline skeleton with `flutter analyze` and `flutter test` gates

**Handoffs to QA:**
- Testable dev build with navigation smoke test checklist
- Documented screen route map for exploratory testing

---

### Sprint 2 (Weeks 3-4): Core Board Matrix Grid

**Features/Modules:**
- `BoardListScreen`: list boards with `AlphaCard`, FAB to create, swipe to archive/delete
- `CreateBoardScreen`: name input, type picker, column editor
- `BoardDetailScreen` — the matrix grid:
  - `TaskColumnFixed` with frozen left column using `LinkedScrollControllerGroup`
  - `ColumnHeaderRow` with horizontal scroll
  - `MarkerGrid` with `MarkerCell` widgets
  - `MarkerCell` tap-to-cycle: empty → DOT → CIRCLE → X → empty
  - `MarkerCell` long-press: `MarkerPickerPopup` with all 6 symbols
  - `InteractiveViewer` for pinch-to-zoom on mobile
- Quick-add task via FAB bottom sheet
- Swipe-to-complete (`Dismissible` on `TaskRowLabel`)
- Drag-to-reorder tasks (`ReorderableListView.builder`)
- Riverpod `markerProvider(taskId, colId)` for granular rebuilds

**Acceptance Criteria:**
- User can create a Weekly board, add 10+ tasks, place markers, complete tasks — all persisted locally
- Frozen task-name column stays vertically synchronized during scroll
- Marker cell cycles through 4 states with visual feedback
- Pinch-to-zoom scales 0.5x to 3.0x on mobile
- Swipe right triggers strikethrough + COMPLETE state
- Grid renders at 60fps with 50 tasks x 7 columns

**Dependencies:**
- Product Designer: grid cell dimensions, marker icon SVGs, color assignments, animation timing
- DevOps: Android/iOS build signing for dogfood distribution

**Handoffs to QA:**
- Dev build with full grid interaction
- Semantic keys on all interactive elements

---

### Sprint 3 (Weeks 5-6): Templates, Migration, Column Management

**Features/Modules:**
- Board templates: Weekly, Monthly, Yearly, GTD Contexts, Daily Hourly, Project Tracker
- `TemplatePickerScreen` with gallery and previews
- Monthly board dynamic column generation (28/29/30/31)
- `MigrationWizardScreen`: 4-step flow (trigger → target → select tasks → confirm)
- Migration logic with transactional integrity in Isar
- Column management: add, rename, reorder, delete
- Board archiving

**Acceptance Criteria:**
- All 6 templates create boards with correct columns
- Monthly template for February 2026 creates 28 columns; March creates 31
- Migration transfers tasks correctly with `>` markers on source and DOT on target
- Cancelled migration mutates nothing (transactional rollback)
- Archived boards disappear from default list; toggleable

**Dependencies:**
- Product Designer: migration wizard UI, template gallery layout, period-elapsed banner
- QA begins regression testing Sprint 2 features

---

### Sprint 4 (Weeks 7-8): Auth, Remote Data Sources, AppSync Integration

**Features/Modules:**
- AWS Cognito integration: sign up, sign in, sign out, token refresh
- Auth state management with Riverpod, auth guard on GoRouter
- Onboarding flow (3-4 page carousel with interactive mini-grid)
- Remote data sources for all entities
- AppSync GraphQL client setup with Dio
- All queries and mutations implemented
- DTO classes and mapper layer
- Repository implementations updated for local + remote

**Acceptance Criteria:**
- User can sign up, verify email, sign in, and see their boards
- Token refresh works transparently
- All CRUD operations persist to both Isar and DynamoDB via AppSync
- `getBoard` returns the full nested board in a single call
- Onboarding shown once, skippable

**Dependencies:**
- DevOps: Cognito User Pool and AppSync API deployed to `dev`; provide endpoint URLs
- Product Designer: sign-in/sign-up screens, onboarding illustrations

---

### Sprint 5 (Weeks 9-10): Offline Sync Engine & Real-Time Subscriptions

**Features/Modules:**
- `SyncQueue` Isar collection
- `SyncEngine` in background isolate with write-ahead queue
- Conflict resolution: last-writer-wins for markers, field-level merge for tasks
- Connectivity awareness via `connectivity_plus`
- Delta sync on app launch/reconnect
- AppSync subscriptions: `onBoardUpdated(boardId)` with echo suppression
- Sync status UI indicator

**Acceptance Criteria:**
- Offline: user can create boards, tasks, markers — all persisted locally
- On reconnect: queued changes sync within 10 seconds
- Two devices: marker change on A appears on B within 2 seconds
- Conflict: Device A changes title, Device B changes priority — both merge correctly
- Sync indicator shows correct state (synced/syncing/pending/offline)
- Failed entries retry with exponential backoff (max 5)

**Dependencies:**
- DevOps: `dogfood` environment with AppSync subscriptions enabled

---

### Sprint 6 (Weeks 11-12): Polish, Platform Optimization, Launch Prep

**Features/Modules:**
- Dark mode with system toggle and manual override
- Web: keyboard shortcuts, hover states, right-click context menus
- Mobile: haptic feedback on marker taps and swipe-to-complete
- Undo support (snackbar) for destructive operations
- Empty states with illustrations
- Loading skeletons
- Collapsed view toggle
- Performance profiling (100 tasks x 31 columns at 60fps)
- Recurring task support (RRULE)
- Settings screen
- Error handling: global error boundary, friendly error screens

**Acceptance Criteria:**
- Dark mode renders with no contrast issues (WCAG AA)
- All keyboard shortcuts work on Chrome without browser conflicts
- Undo snackbar appears 5 seconds; tapping reverts and re-syncs
- Monthly board at 60fps on mid-range Android
- App passes `flutter analyze` with zero warnings
- App size: <15MB Android APK, <25MB iOS IPA

**Dependencies:**
- Product Designer: dark mode tokens, empty state illustrations, settings layout
- DevOps: `staging` and `prod` environments; app store configuration
- QA: full regression pass; performance benchmark testing

---

## 4. Technical Implementation Details

### 4a. Board Matrix Grid Widget

**Problem:** Frozen left column scrolling vertically in sync with the marker grid, while the marker grid also scrolls horizontally (spreadsheet "frozen pane" pattern).

**Architecture:**

```
BoardMatrixView (StatefulWidget)
├── BoardToolbar
├── Row
│   ├── SizedBox(width: 200)  // FROZEN LEFT COLUMN
│   │   ├── CornerCell()
│   │   └── ListView.builder(controller: _taskColumnScrollController)
│   │       └── TaskRowLabel(task)
│   └── Expanded  // SCROLLABLE MARKER AREA
│       ├── SingleChildScrollView(horizontal, controller: _horizontalScrollController)
│       │   └── ColumnHeaderRow(columns)
│       └── SingleChildScrollView(horizontal, controller: _horizontalScrollController)
│           └── ListView.builder(controller: _markerGridScrollController)
│               └── MarkerRow(task, columns)
└── FloatingActionButton
```

**Key:** `LinkedScrollControllerGroup` synchronizes the two vertical `ScrollController` instances. Same horizontal `ScrollController` links header and grid horizontal scroll.

**Edge Cases:**
- `InteractiveViewer` wraps the entire `Row` on mobile but must be disabled on web
- Keyboard opening must not jump the grid (`resizeToAvoidBottomInset: false`)

**Performance:**
- `ListView.builder` virtualizes rows (only visible rows built)
- Each `MarkerCell` watches only `markerProvider(taskId, colId)` — single-cell rebuild
- Avoid `Table` widget (not virtualized)

---

### 4b. Marker Cycling Interaction

**State Machine:**

```
tap(EMPTY)     → DOT
tap(DOT)       → CIRCLE
tap(CIRCLE)    → X
tap(X)         → EMPTY (delete)
tap(MIGRATED)  → no-op (read-only)
longPress(any) → MarkerPickerPopup → select symbol
```

**Implementation:**
- `GestureDetector` with `onTap` and `onLongPress`
- `AnimatedSwitcher` with `ScaleTransition` (150ms, `Curves.easeOutBack`)
- `HapticFeedback.lightImpact()` on tap (no-op on web)
- No debounce needed — rapid cycling is expected behavior

---

### 4c. Offline Sync Engine

**Architecture:**

```
UI Thread                          Background Isolate
─────────                          ──────────────────
User taps marker
  → Repository.cycleMarker()
    → Write to Isar (immediate)
    → Insert SyncQueueEntry(PENDING)
    → Notify SyncEngine via SendPort
                                   SyncEngine.processQueue():
                                     dequeue oldest PENDING
                                     mark IN_FLIGHT
                                     try: appSyncClient.mutate()
                                       resolve conflicts if needed
                                       delete from queue
                                     catch: increment retryCount
                                       backoff, retry (max 5)
```

**Conflict Resolution:**
- **Markers:** Last-writer-wins (single enum value, no partial merge needed)
- **Tasks:** Field-level merge with timestamp comparison
- **Boards/Columns:** Last-writer-wins

**Edge Cases:**
- App killed while IN_FLIGHT → on relaunch, reset to PENDING
- Entity deleted locally while CREATE queued → skip/delete queue entry
- Migration creates multiple entities → batch into single `migrateTasks` mutation

---

### 4d. Migration Flow

**`MigrateTasksUseCase` executes in an Isar transaction:**

1. Mark each source task as `MIGRATED`, add `>` marker
2. Create new task in target board with `OPEN` state, `migratedFromTaskId` link
3. Create DOT markers on target board columns
4. Enqueue entire migration as single sync operation

**Edge Cases:**
- Tasks already migrated by another device → check state, skip, warn
- Target board created within same transaction
- Power loss mid-transaction → Isar atomic rollback

---

### 4e. AppSync GraphQL Integration

**Client:** Dio-based with auth interceptor (auto token refresh on 401)

**Subscriptions:** WebSocket via AppSync protocol with echo suppression (`deviceId` comparison)

**Key Query — Load Full Board:**
```graphql
query GetBoard($id: ID!) {
  getBoard(id: $id) {
    id name type archived createdAt
    columns { id label position color type }
    tasks {
      id title description position state priority deadline
      markers { id columnId symbol createdAt updatedAt }
    }
  }
}
```

**Edge Cases:**
- WebSocket drop → reconnect with exponential backoff + delta sync catch-up
- Token expiry during subscription → detect disconnect, refresh, re-establish
- Large board (100+ tasks) → monitor response sizes vs AppSync 256KB limit

---

## 5. Code Standards & Conventions

### Naming

| Element | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `board_detail_screen.dart` |
| Classes | `PascalCase` | `BoardMatrixView` |
| Variables/functions | `camelCase` | `syncQueueManager` |
| Enums | `PascalCase` type, `camelCase` values | `MarkerSymbol.dot` |
| Providers | `camelCase` + `Provider` | `boardDetailProvider` |
| Test files | `*_test.dart` mirroring source | `test/data/repositories/board_repository_impl_test.dart` |

### PR Requirements

- **Title**: `type(scope): description` (Conventional Commits)
- **Body**: What changed and why; screenshots for UI changes
- **Checklist**: `flutter analyze` clean, tests pass, new tests for new logic, no `print()` statements
- **Review**: minimum 1 approval; no self-merge

### Documentation

- Public API classes have `///` doc comments
- Non-obvious algorithms have inline `//` comments
- ADRs for significant technical choices in `docs/adr/`

---

## 6. Collaboration Points

### 6.1 Product Designer

- **Sprint planning:** Designer presents specs 2-3 days before sprint start
- **Mid-sprint check-in:** 15-minute review of in-progress implementations
- **Handling ambiguity:** Implement reasonable default, flag in PR for review. Don't block on minor edge cases.
- **Widget catalog:** Debug-only screen for designer validation of reusable components

### 6.2 QA Engineer

- **Sprint end handoff:** Testable build (APK, TestFlight, web URL) with test guide
- **Semantic keys:** All interactive widgets have `Key` values: `Key('widget_type_entity_id')`
- **Debug menu:** Force-clear sync queue, trigger migration, reset onboarding, view Isar contents
- **Testability:** All repos return `Future<T>`, animations disableable via flag, network layer injectable

### 6.3 DevOps Engineer

- **Sprint 1:** CI pipeline, build flavors, signing setup
- **Environment variables contract:**

| Variable | Description |
|---|---|
| `APPSYNC_ENDPOINT` | GraphQL API URL |
| `COGNITO_USER_POOL_ID` | Cognito pool identifier |
| `COGNITO_APP_CLIENT_ID` | App client for mobile/web |
| `ENVIRONMENT` | `dev` / `dogfood` / `staging` / `prod` |

- **Ongoing:** Notify DevOps when new native plugins added or minimum SDK versions change

---

## 7. Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | **Grid performance on large boards** (31 cols x 100 tasks) | Medium | High | `ListView.builder` virtualization, single-cell provider rebuild, profile in Sprint 2. Fallback: column virtualization or collapsed view. |
| 2 | **Isar Web support instability** | Medium | High | Repository interface abstraction from day one. Drift + sqlite3 WASM as fallback. Test web in Sprint 1. |
| 3 | **Sync conflicts causing data loss** | Medium | Critical | Field-level tracking, comprehensive conflict resolution unit tests, debug conflict log. Never silently discard data. |
| 4 | **Scroll synchronization bugs** | Medium | Medium | `linked_scroll_controller` package (Google-maintained). Widget tests for position parity. Disable zoom if it interferes. |
| 5 | **AppSync subscription reliability** | High | Medium | Delta sync on reconnect, heartbeat monitoring, 24-hour reconnection. Fallback: 30-second polling. |
