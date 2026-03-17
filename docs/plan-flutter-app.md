# AlPHA — Flutter Development Plan

## Flutter Application Architecture for the Alastair Planner & Habit App

---

## 1. Project Structure

Use a **feature-first** layout with a shared core layer. Each domain (boards, tasks, markers, migration) is self-contained while sharing models, services, and design-system primitives.

```
lib/
  app.dart                          # MaterialApp / GoRouter root
  main.dart                         # Entry point, DI bootstrap

  core/
    constants/                      # App-wide constants, enums
    errors/                         # Failure classes, exception mappers
    extensions/                     # Dart extension methods
    utils/                          # Date helpers, UUID generator, etc.
    di/                             # Riverpod overrides, provider scope
    network/                        # HTTP client, interceptors, connectivity

  data/
    models/                         # Freezed data classes (Board, Task, Column, Marker)
    repositories/                   # Repository implementations
    datasources/
      local/                        # Isar collections, DAOs
      remote/                       # AWS API client, DTOs
    mappers/                        # Entity <-> DTO <-> Isar model mappers
    sync/                           # Sync engine (queue, conflict resolution)

  domain/
    entities/                       # Pure domain entities (if separating from data models)
    repositories/                   # Abstract repository interfaces
    usecases/                       # Business logic units (MigrateTasksUseCase, etc.)

  features/
    board/
      presentation/
        screens/                    # BoardListScreen, BoardDetailScreen
        widgets/                    # GridMatrix, ColumnHeader, TaskRow, MarkerCell
        controllers/                # Riverpod AsyncNotifiers
      providers/                    # Feature-scoped providers

    task/
      presentation/
        screens/                    # TaskDetailScreen, TaskCreateSheet
        widgets/                    # TaskTile, SwipeToDismiss wrapper
        controllers/
      providers/

    migration/
      presentation/
        screens/                    # MigrationWizardScreen
        widgets/                    # MigrationTaskSelector, MigrationSummary
        controllers/
      providers/

    templates/
      presentation/
        screens/                    # TemplatePickerScreen
        widgets/
      providers/
      data/                         # Hardcoded template definitions

    settings/
      presentation/
        screens/                    # SettingsScreen, ThemePickerScreen
        controllers/
      providers/

    onboarding/
      presentation/
        screens/                    # OnboardingCarousel

  design_system/
    theme/                          # AppTheme, ColorTokens, TypographyTokens
    components/                     # AlphaButton, AlphaCard, AlphaChip, MarkerIcon
    layout/                         # ResponsiveScaffold, AdaptiveGrid

assets/
  fonts/
  images/
  templates/                        # JSON template definitions

test/
  unit/
  widget/
  integration/
```

**Key conventions:**
- Every Dart file uses `part` / `part of` only for Freezed generated code; otherwise standard imports.
- Feature folders mirror each other structurally so new contributors can navigate by pattern.
- The `domain/` layer is kept thin -- only introduce use-case classes when business logic is non-trivial (migration, recurrence expansion). Simple CRUD goes directly through repositories.

---

## 2. State Management

### Recommendation: Riverpod (v2, with code generation)

| Factor | Riverpod Advantage |
|--------|--------------------|
| Compile-time safety | Providers are globally declared; no runtime lookup failures |
| Testability | Override any provider in tests without DI gymnastics |
| Async first-class | `AsyncNotifierProvider` maps perfectly to load-board / sync states |
| Granular rebuilds | Selecting specific fields (e.g., a single marker) avoids full-grid rebuilds -- critical for a large matrix |
| No BuildContext needed | Repository/sync logic can read providers without widget tree access |
| Flutter Web friendly | No platform channels; pure Dart |

### Provider Architecture for the Board Grid

```
boardListProvider           -> AsyncNotifierProvider<List<Board>>
boardDetailProvider(id)     -> AsyncNotifierProvider<Board> (family)
boardColumnsProvider(id)    -> Provider derived from boardDetail, returns Column list
boardTasksProvider(id)      -> Provider derived from boardDetail, returns Task list
markerProvider(taskId, colId) -> Provider derived from boardDetail, returns Marker?
syncStatusProvider          -> StateProvider<SyncStatus>
```

The matrix grid widget will use `ref.watch(markerProvider(taskId, colId))` so that tapping a single cell only rebuilds that one `MarkerCell` widget, not the entire grid. This is essential for performance on monthly boards (31 columns x N tasks).

---

## 3. Core Features & Screens

### 3.1 Screen Map

| Screen | Route | Description |
|--------|-------|-------------|
| **Home / Board List** | `/` | Shows all boards (active + archived toggle). Cards with board name, type badge, progress ring. FAB to create. |
| **Board Detail (Matrix)** | `/board/:id` | The core grid view. Fixed left column for task titles, scrollable column headers + marker cells. |
| **Task Detail** | `/board/:id/task/:taskId` | Bottom sheet or full page: title, description, priority, deadline, recurrence rule, marker summary. |
| **Create/Edit Board** | `/board/new` or `/board/:id/edit` | Name, type picker (daily/weekly/monthly/yearly/custom), column editor. |
| **Template Picker** | `/templates` | Gallery of pre-built board templates. Tap to preview, confirm to create. |
| **Migration Wizard** | `/board/:id/migrate` | Multi-step: select target board (or create new), pick tasks, confirm. |
| **Settings** | `/settings` | Theme, default columns, sync account, export/import. |
| **Onboarding** | `/onboarding` | 3-4 page carousel explaining the Alastair Method with interactive mini-grid demo. |

### 3.2 Widget Breakdown for the Matrix View

This is the most architecturally significant screen.

```
BoardMatrixView
 ├── BoardToolbar              // Board name, mode toggle, filter, overflow menu
 ├── InteractiveViewer          // Wraps the grid for pinch-to-zoom + pan
 │   └── Row
 │       ├── TaskColumnFixed    // Frozen left column (sticky)
 │       │   ├── ColumnHeaderCell (blank corner)
 │       │   └── ReorderableListView
 │       │       └── TaskRowLabel  // Task title + swipe-to-complete wrapper
 │       │           ├── Dismissible (swipe right = complete, swipe left = cancel)
 │       │           └── Text(task.title)
 │       └── Expanded
 │           └── SingleChildScrollView (horizontal)
 │               └── Column
 │                   ├── ColumnHeaderRow
 │                   │   └── ColumnHeaderCell * N  // "Mon", "Email", etc.
 │                   └── MarkerGrid
 │                       └── MarkerRow * M
 │                           └── MarkerCell * N   // Tap to cycle marker
 │                               └── MarkerIcon(symbol)
 └── FloatingActionButton       // Quick-add task
```

**Synchronizing vertical scroll:** Use a shared `ScrollController` (or `LinkedScrollControllerGroup` from the `linked_scroll_controller` package) so the frozen task-name column and the scrollable marker grid stay vertically aligned.

**MarkerCell tap behavior:**
- Single tap: cycle through `empty -> DOT -> CIRCLE -> X -> empty`
- Long press: open a `MarkerPickerPopup` with all symbols (DOT, X, CIRCLE, STAR, TILDE, MIGRATED)
- Visual feedback: ripple + brief scale animation on the marker icon

**Swipe-to-complete on TaskRowLabel:**
- `Dismissible` widget with `confirmDismiss` callback
- Swipe right: sets `task.state = COMPLETE`, draws strikethrough animation across the row
- Swipe left: sets `task.state = CANCELLED`

**Drag-to-reorder:**
- `ReorderableListView.builder` for the task column
- On reorder, update `task.position` for affected rows and persist

### 3.3 Board Templates

Hardcode a set of template definitions as Dart constants (or JSON assets):

| Template | Type | Columns |
|----------|------|---------|
| Weekly Planner | WEEKLY | Mon, Tue, Wed, Thu, Fri, Sat, Sun |
| Monthly Planner | MONTHLY | 1..28/30/31 (dynamic based on selected month) |
| Yearly Future Log | YEARLY | Jan..Dec |
| GTD Contexts | CONTEXT | Calendar, Email, Phone, Projects, Thinking, Waiting For |
| Daily Hourly | DAILY | 6am..9pm |
| Project Tracker | CUSTOM | Phase 1, Phase 2, Phase 3, Testing, Launch |

### 3.4 Migration Flow

**Step 1 -- Trigger:** System checks if the board's period has elapsed. If yes, a banner appears: "This period has ended. Migrate incomplete tasks?"

**Step 2 -- Select target:** User picks an existing board or creates a new one from a template.

**Step 3 -- Pick tasks:** A checklist of all tasks with state OPEN or IN_PROGRESS. Pre-selected by default.

**Step 4 -- Confirm:** Migrated tasks get `>` marker on the source board. New `DOT` markers are created on the target board. Cancelled tasks get strikethrough on the source board.

---

## 4. Platform-Specific Considerations

### 4.1 Responsive Layout Strategy

Use a `ResponsiveScaffold` wrapper that switches layout based on screen width:

| Breakpoint | Layout | Target |
|------------|--------|--------|
| < 600px | Single-column, bottom nav, full-screen sheets | Phone |
| 600-1024px | Rail nav, master-detail possible | Tablet |
| > 1024px | Side nav drawer + wide content area, dialogs instead of sheets | Web / Desktop |

The board matrix itself does not change structure across breakpoints -- it is always a horizontally-scrollable grid. What changes is the chrome around it.

### 4.2 Mobile-Specific

- **Horizontal scrolling:** The grid's column area is in a `SingleChildScrollView(scrollDirection: Axis.horizontal)`. The task-name column is frozen outside this scroll view.
- **Pinch-to-zoom:** Wrap the entire grid in `InteractiveViewer` with `minScale: 0.5`, `maxScale: 3.0`. Critical for monthly boards (31 columns) on phone screens.
- **FAB quick-add:** Opens a minimal bottom sheet: just a text field and a submit button.
- **Haptic feedback:** `HapticFeedback.lightImpact()` on marker cycle taps.

### 4.3 Web-Specific

- **Mouse hover states:** MarkerCells show a subtle highlight on hover.
- **Keyboard shortcuts:** `N` for new task, `Cmd+Z` for undo, arrow keys to navigate cells, `Space` to cycle marker.
- **URL-based navigation:** Deep links like `/board/abc-123` work naturally with GoRouter.
- **No `InteractiveViewer` on web:** On wide screens the grid fits naturally; use standard scroll + `Ctrl+scroll` for zoom if needed.
- **Right-click context menus:** On web/desktop, right-click a task row to get: Edit, Delete, Migrate, Change Priority.

---

## 5. Offline-First Architecture

### 5.1 Local Database: Isar

| DB | Pros | Cons | Verdict |
|----|------|------|---------|
| **Isar** | Dart-native, fast, supports Flutter Web (via IndexedDB), strong query API | Newer ecosystem | **Selected** |
| Hive | Simple key-value | No relational queries, manual indexing | Not ideal for relational grid data |
| Drift | SQL power, type-safe | No Flutter Web support without sqlite3 WASM | Web support friction |

**Fallback:** If Isar's web support proves unstable, fall back to `drift` + `sqlite3` WASM with a repository interface abstracting the difference.

### 5.2 Sync Strategy

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  UI Layer   │────>│  Repository  │────>│  Local DB   │
│             │<────│  (single     │<────│  (Isar)     │
│             │     │   source of  │     │             │
│             │     │   truth)     │     └──────┬──────┘
│             │     └──────────────┘     ┌──────▼──────┐
│             │                         │ Sync Engine │
│             │                         │ (background)│
│             │                         └──────┬──────┘
│             │                         ┌──────▼──────┐
│             │                         │  AWS Backend│
│             │                         └─────────────┘
```

**Key principles:**
1. **Local-first:** All reads come from Isar. The UI never waits for the network.
2. **Write-ahead queue:** Every mutation is written to Isar immediately, then enqueued in a `SyncQueue` collection.
3. **Conflict resolution:** Last-write-wins at the field level, using `updated_at` timestamps.
4. **Connectivity awareness:** Use `connectivity_plus` to detect online/offline transitions. Flush sync queue on reconnect.
5. **Delta sync:** On app launch (or reconnect), pull changes since `last_sync_at` from the server.

### 5.3 Sync Queue Schema

```
SyncQueueEntry
├── id: int (auto)
├── entity_type: enum (BOARD | COLUMN | TASK | MARKER)
├── entity_id: String (UUID)
├── operation: enum (CREATE | UPDATE | DELETE)
├── payload: String (JSON of the changed fields)
├── created_at: DateTime
├── retry_count: int
├── status: enum (PENDING | IN_FLIGHT | FAILED)
```

---

## 6. Data Layer

### 6.1 Models (Freezed)

All models use `freezed` for immutability + `json_serializable` for JSON encoding.

**Board**
- `id`: String (UUID v4), `name`: String, `type`: `BoardType` enum
- `ownerId`: String, `createdAt`/`updatedAt`: DateTime, `archived`: bool
- `periodStart`/`periodEnd`: DateTime? (for time-based boards)

**BoardColumn** (named to avoid Dart keyword collision)
- `id`: String, `boardId`: String, `label`: String, `position`: int
- `color`: String? (hex), `type`: `ColumnType` enum

**Task**
- `id`: String, `boardId`: String, `title`: String, `description`: String?
- `position`: int, `state`: `TaskState` enum, `priority`: `TaskPriority` enum
- `deadline`: DateTime?, `recurring`: bool, `recurrenceRule`: String?
- `createdAt`/`updatedAt`/`completedAt`: DateTime?, `migratedFromTaskId`: String?

**Marker**
- `id`: String, `taskId`: String, `columnId`: String
- `symbol`: `MarkerSymbol` enum (DOT, X, CIRCLE, STAR, TILDE, MIGRATED)
- `createdAt`/`updatedAt`: DateTime

### 6.2 Repository Interfaces

```dart
abstract class BoardRepository {
  Future<List<Board>> getBoards({bool includeArchived = false});
  Future<Board> getBoardById(String id);
  Future<Board> createBoard(Board board);
  Future<Board> updateBoard(Board board);
  Future<void> archiveBoard(String id);
  Future<void> deleteBoard(String id);
  Stream<List<Board>> watchBoards();
}

abstract class TaskRepository {
  Future<List<Task>> getTasksByBoard(String boardId);
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> reorderTasks(String boardId, List<String> orderedIds);
  Future<List<Task>> migrateTasks(List<String> taskIds, String targetBoardId);
  Stream<List<Task>> watchTasksByBoard(String boardId);
}

abstract class MarkerRepository {
  Future<List<Marker>> getMarkersByBoard(String boardId);
  Future<Marker> setMarker(Marker marker);    // upsert
  Future<void> removeMarker(String taskId, String columnId);
  Future<Marker> cycleMarker(String taskId, String columnId);
  Stream<List<Marker>> watchMarkersByBoard(String boardId);
}

abstract class ColumnRepository {
  Future<List<BoardColumn>> getColumnsByBoard(String boardId);
  Future<BoardColumn> createColumn(BoardColumn column);
  Future<BoardColumn> updateColumn(BoardColumn column);
  Future<void> deleteColumn(String id);
  Future<void> reorderColumns(String boardId, List<String> orderedIds);
}
```

### 6.3 Repository Implementation Pattern

```dart
class BoardRepositoryImpl implements BoardRepository {
  final BoardLocalDataSource _local;   // Isar
  final BoardRemoteDataSource _remote; // AWS API
  final SyncQueue _syncQueue;

  // All reads go to _local
  // All writes go to _local first, then enqueue to _syncQueue
}
```

---

## 7. Navigation

### Recommendation: GoRouter

GoRouter is the officially recommended Flutter navigation package, supports deep linking on all platforms (critical for web), and integrates cleanly with Riverpod.

### 7.1 Route Tree

```
/                              -> BoardListScreen
/onboarding                    -> OnboardingScreen (shown once)
/board/new                     -> CreateBoardScreen
/board/:boardId                -> BoardDetailScreen (matrix view)
/board/:boardId/edit           -> EditBoardScreen
/board/:boardId/task/:taskId   -> TaskDetailScreen
/board/:boardId/migrate        -> MigrationWizardScreen
/templates                     -> TemplatePickerScreen
/settings                      -> SettingsScreen
```

### 7.2 Shell Routes

Use `ShellRoute` for persistent bottom navigation bar (mobile) or side rail (tablet/desktop):

```
ShellRoute (with ResponsiveScaffold)
 ├── /                 (Boards tab)
 ├── /templates        (Templates tab)
 └── /settings         (Settings tab)
```

Sub-routes like `/board/:boardId` push on top of the shell.

---

## 8. Theming & Design System

### 8.1 Design Tokens

```dart
abstract class AppColors {
  // Marker colors
  static const markerDot = Color(0xFF4A90D9);      // Blue dot
  static const markerCircle = Color(0xFFF5A623);    // Orange circle
  static const markerX = Color(0xFF7ED321);          // Green X (done)
  static const markerStar = Color(0xFFD0021B);       // Red star (deadline)
  static const markerTilde = Color(0xFF9013FE);      // Purple tilde (recurring)
  static const markerMigrated = Color(0xFF8B8B8B);   // Gray migrated arrow

  // Grid
  static const gridLine = Color(0xFFE0E0E0);
  static const gridHeaderBg = Color(0xFFF5F5F5);
  static const taskRowAlt = Color(0xFFFAFAFA);       // Zebra striping
}
```

### 8.2 Component Library

| Component | Purpose |
|-----------|---------|
| `MarkerIcon` | Renders any `MarkerSymbol` as a styled icon/shape |
| `AlphaCard` | Consistent card styling for board list items |
| `AlphaButton` | Primary, secondary, text button variants |
| `GridCell` | Base cell widget with consistent sizing, tap target (min 44x44) |
| `StrikethroughText` | Animated strikethrough for completed tasks |
| `EmptyState` | Illustration + message for empty boards |

### 8.3 Dark Mode

Support `ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`. All color tokens have light/dark variants.

---

## 9. Phased Delivery

### Phase 0 -- Foundation (Week 1-2)

**Goal:** Buildable skeleton with navigation, theming, and local persistence.

- Flutter project setup with folder structure
- Riverpod + GoRouter + Freezed + Isar integration
- Define all data models
- Implement Isar schemas and local data sources
- Design system tokens + base components (MarkerIcon, GridCell, AlphaCard)
- ResponsiveScaffold with bottom nav / side rail
- Route definitions (all screens as stubs)

### Phase 1 -- MVP: Core Grid (Week 3-5)

**Goal:** A fully functional single-board experience, offline only.

- **BoardListScreen:** List, create, delete boards
- **BoardDetailScreen:** Full matrix grid with:
  - Fixed task column + horizontally scrollable marker columns
  - Linked vertical scroll controllers
  - Tap-to-cycle markers
  - Long-press marker picker
  - Swipe-to-complete / swipe-to-cancel
  - Drag-to-reorder tasks
  - Quick-add task via FAB
- **Column management:** Add, rename, reorder, delete
- **Task detail sheet:** Edit title, description, priority, deadline
- InteractiveViewer for pinch-to-zoom (mobile only)

**Exit criteria:** A user can create a weekly board, add tasks, mark them across days, complete them, and reorder them -- all persisted locally.

### Phase 2 -- Templates & Migration (Week 6-7)

- Board templates (Weekly, Monthly, GTD Contexts, etc.)
- Migration Wizard with end-of-period detection
- Board archiving
- Recurring task support (RRULE)

### Phase 3 -- Polish & Platform Optimization (Week 8-9)

- Onboarding carousel
- Dark mode
- Keyboard shortcuts (web), right-click menus (web/desktop), hover states
- Haptic feedback (mobile)
- Empty states and loading skeletons
- Undo support (snackbar)
- Performance profiling (60fps on 50+ task boards)
- Collapsed view toggle

### Phase 4 -- Sync & Auth (Week 10-12)

- AWS Cognito auth (sign up, sign in, sign out, token refresh)
- Remote data sources (API client with Dio)
- Sync engine: write-ahead queue, background isolate, delta pull, conflict resolution
- Sync status indicator in UI
- Multi-device testing

### Phase 5 -- v1.1 Enhancements (Week 13+)

- Search, filters, statistics dashboard
- Export (CSV/PDF)
- Local notifications for deadlines
- Home screen widgets (iOS/Android)
- Board sharing
- Customizable marker sets
- Accessibility (screen reader, large-tap-target mode)

---

## Dependencies Summary

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` | State management |
| `go_router` | Navigation |
| `freezed` + `freezed_annotation` + `json_annotation` | Immutable models |
| `isar` + `isar_flutter_libs` | Local database |
| `dio` | HTTP client |
| `connectivity_plus` | Network state detection |
| `linked_scroll_controller` | Synced scroll for frozen column |
| `uuid` | UUID generation |
| `intl` | Date formatting, localization |
| `flutter_slidable` | Swipe actions on task rows |
| `rrule` | Recurrence rule parsing |
| `amazon_cognito_identity_dart_2` (or `amplify_auth_cognito`) | AWS Cognito auth |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| **Grid performance with large boards** (31 cols x 100 tasks = 3,100 cells) | Use `ListView.builder` for rows (virtualized). Profile early with synthetic data in Phase 1. |
| **Isar web support instability** | Abstract behind repository interface. Have Drift + sqlite3 WASM as fallback. Test web early in Phase 0. |
| **Sync conflicts on markers** | Field-level last-write-wins with timestamps. Users rarely edit the same cell simultaneously. |
| **Scroll synchronization bugs** | Use `linked_scroll_controller` package. Write widget tests for scroll sync in Phase 1. |
| **Scope creep in Phase 1** | MVP is deliberately narrow: one board type, no sync, no templates. |
