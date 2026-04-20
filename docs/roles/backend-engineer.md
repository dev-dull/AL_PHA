# AlPHA — Backend Engineer Implementation Plan

## 1. Role & Responsibilities

### Backend Engineer Owns

| Area | Specifics |
|------|-----------|
| **API Design** | GraphQL schema authoring and evolution (`schema/schema.graphql`), input/output type definitions, deprecation management |
| **Lambda Resolvers** | All AppSync resolver functions: board, task, column, marker, migration, sync, conflict resolution |
| **DynamoDB Data Access** | Single-table design implementation, query/write patterns, condition expressions, transaction logic, GSI usage |
| **Business Logic** | Task state machine enforcement, marker cycling rules, migration atomicity, position management, recurrence evaluation |
| **Sync & Conflict Resolution** | Delta sync query implementation, version-based conflict detection Lambda, field-level merge for tasks, last-writer-wins for markers, tombstone management |
| **EventBridge Events** | Event producer logic (publishing domain events), event consumer Lambdas (recurring task creation, migration reminders) |
| **Unit & Integration Tests** | Every resolver unit-tested with mocked DynamoDB; integration tests against local DynamoDB |
| **Contract Tests** | Backend-side schema validation ensuring Lambda responses conform to GraphQL types |
| **API Documentation** | Maintaining schema as the single source of truth, documenting access patterns and error codes |

### DevOps Owns (Not Backend's Responsibility)

- CDK stack definitions and infrastructure provisioning (auth-stack, data-stack, compute-stack, etc.)
- CDK Pipeline configuration and CI/CD orchestration
- Multi-environment deployment (dev/dogfood/staging/prod)
- IAM roles and policies (Backend specifies what permissions are needed; DevOps implements)
- CloudWatch dashboards and alarms configuration
- Cost guardrails (Budgets, concurrency limits)
- DNS, CloudFront, S3 bucket policies

### Frontend Owns (Not Backend's Responsibility)

- AppSync client SDK configuration and cache management
- Optimistic UI logic (local mutation application before server response)
- Offline queue management and replay
- Subscription connection lifecycle (connect/disconnect/reconnect)
- Device echo suppression (filtering subscription events by `deviceId`)
- UI rendering of the board grid, marker states, and migration flow

### Shared Responsibilities

| Area | Backend | Frontend | DevOps |
|------|---------|----------|--------|
| GraphQL schema | Authors & maintains | Consumes & validates client codegen | Deploys schema to AppSync |
| Error handling | Defines error taxonomy & response format | Surfaces errors to user, handles retries | Alarms on error rates |
| Sync protocol | Implements delta query & conflict resolver | Implements client-side sync state machine | Monitors sync metrics |

---

## 2. Development Environment Setup

### 2.1 Node.js / TypeScript Toolchain

- **Node.js**: v20 LTS (matches Lambda runtime `nodejs20.x`)
- **TypeScript**: 5.x with strict mode enabled
- **Package manager**: npm (aligns with CDK project defaults)
- **Key dependencies**:
  - `@aws-sdk/client-dynamodb` and `@aws-sdk/lib-dynamodb` (DynamoDB Document Client)
  - `@aws-sdk/util-dynamodb` (marshalling)
  - `uuid` (entity ID generation)
  - `rrule` (recurrence rule evaluation for the recurring task engine)
- **Build tool**: esbuild (tree-shaking, fast bundling, configured via CDK `NodejsFunction` construct)
- **Linting**: ESLint with `@typescript-eslint/recommended`
- **Formatting**: Prettier

### 2.2 Local DynamoDB

A `docker-compose.yml` at the project root runs DynamoDB Local:

```yaml
services:
  dynamodb-local:
    image: amazon/dynamodb-local:latest
    ports:
      - "8000:8000"
    command: "-jar DynamoDBLocal.jar -sharedDb -inMemory"
```

A setup script creates the table with GSIs matching the CDK definition. This script runs before integration tests and during `npm run dev:setup`.

Configuration: Lambda code reads `DYNAMODB_ENDPOINT` environment variable. When set (local dev), it overrides the default AWS endpoint. In deployed environments, this variable is absent, and the SDK uses the default regional endpoint.

### 2.3 AppSync Local Testing

Two approaches, used in combination:

1. **Direct Lambda invocation**: For most development, test resolvers by invoking the Lambda handler function directly with mock AppSync event payloads. This is faster and simpler than running a full AppSync mock.

2. **Amplify Mock (optional)**: `amplify mock api` can serve a local GraphQL endpoint for frontend integration testing. However, this is primarily a frontend concern. Backend tests should not depend on it.

### 2.4 Jest Setup

- **Framework**: Jest with `ts-jest` preset
- **Test structure**: Mirror the `lambda/` directory structure under `test/`
  - `test/unit/resolvers/` -- unit tests with mocked DynamoDB
  - `test/integration/` -- tests against DynamoDB Local
  - `test/contracts/` -- schema conformance tests
- **Coverage**: Configured with `--coverage` flag, thresholds enforced in `jest.config.ts`:
  - Branches: 85%, Functions: 90%, Lines: 90%, Statements: 90%
- **Mocking**: `jest.mock('@aws-sdk/lib-dynamodb')` for unit tests. Integration tests use real DynamoDB Local client.

### 2.5 esbuild Configuration

Handled by CDK's `NodejsFunction` construct, but locally replicated for standalone testing:

- Target: `node20`
- Format: `esm` (or `cjs` if module resolution issues arise)
- External: `@aws-sdk/*` (provided by Lambda runtime, excluded from bundle)
- Tree-shaking: enabled
- Minification: enabled for staging/prod, disabled for dev (readable stack traces)
- Source maps: enabled for all environments

### 2.6 Debugging Lambda Locally

- **VS Code launch configuration**: Run Lambda handler functions directly with `ts-node` or compiled JS via the VS Code debugger.
- **SAM CLI (optional)**: `sam local invoke` with the CDK-synthesized template can simulate the full Lambda execution environment. Useful for debugging IAM or timeout issues but slower.
- **Environment variables**: Managed via a `.env.local` file (git-ignored) that sets `DYNAMODB_ENDPOINT=http://localhost:8000`, `TABLE_NAME=alpha-dev-main`, `STAGE=dev`.

---

## 3. Sprint-by-Sprint Breakdown (12 Weeks, 6 Sprints)

### Sprint 1 (Weeks 1-2): Foundation -- Auth & Board CRUD

**Lambda Resolvers to Implement:**
- `createBoard` -- Creates board item under `USER#<userId>` partition, generates boardId, creates default columns based on board type
- `getBoard` -- Single DynamoDB Query on `PK = BOARD#<boardId>`, returns columns + tasks + markers, with ownership verification
- `listBoards` -- Query on `PK = USER#<userId>`, `SK begins_with BOARD#`, supports pagination via `nextToken` and filtering by `archived`
- `updateBoard` -- Conditional update on board item (name, type changes), version increment
- `deleteBoard` -- Soft delete (set `_deleted = true`, update `_lastModified`)
- `archiveBoard` -- Set `archived = true` on the board item

**DynamoDB Access Patterns:**
- `PK = USER#<userId>, SK begins_with BOARD#` (list user's boards)
- `PK = BOARD#<boardId>` (load full board contents)
- `GSI1PK = BOARD#<boardId>` (verify board exists and retrieve owner)
- Conditional writes with `_version` check for optimistic locking

**Integration Points with Frontend:**
- Deliver finalized GraphQL schema for Board types, Query.getBoard, Query.listBoards, Mutation.createBoard
- Agree on error response format (see Section 7)
- Frontend can begin building board list screen and board creation flow

**Test Coverage:**
- Unit tests for all 6 resolvers (mocked DynamoDB): valid inputs, invalid inputs, authorization failures, not-found cases
- Integration tests against DynamoDB Local for createBoard and getBoard round-trip
- Minimum 90% line coverage on resolver code

**Dependencies:**
- DevOps: `dev` environment CDK stack deployed (DynamoDB table, Cognito User Pool, AppSync API with schema, compute stack with placeholder Lambdas)
- DevOps: CI pipeline running backend unit tests on PR
- Frontend: Cognito auth flow implemented (sign-up, sign-in, token refresh)

---

### Sprint 2 (Weeks 3-4): The Grid -- Columns, Tasks, Markers

**Lambda Resolvers to Implement:**
- `addColumn` -- Append column to board with auto-calculated position, validate max column count (31 for monthly boards)
- `updateColumn` -- Update label, color, type with version check
- `removeColumn` -- Soft delete column, cascade soft-delete to all markers referencing this column (TransactWriteItems)
- `reorderColumns` -- Accept ordered list of columnIds, rewrite `SK` position prefixes in a transaction
- `addTask` -- Append task with auto-calculated position, validate board exists and user owns it
- `updateTask` -- Field-level update with version check
- `completeTask` -- Set state=COMPLETE, completedAt=now, version increment
- `cancelTask` -- Set state=CANCELLED, version increment
- `reorderTasks` -- Transactional position update for affected task items
- `setMarker` -- Upsert marker at `MARKER#<taskId>#<columnId>`, idempotent
- `removeMarker` -- Delete marker item (or soft-delete for sync)
- `cycleMarker` -- Read current marker state, advance to next in cycle (empty->DOT->CIRCLE->X->empty), conditional write
- `shiftContext` -- TransactWriteItems: remove marker from source column, create marker on target column atomically

**DynamoDB Access Patterns:**
- `PK = BOARD#<boardId>, SK begins_with COL#` (list columns)
- `PK = BOARD#<boardId>, SK begins_with TASK#` (list tasks)
- `PK = BOARD#<boardId>, SK = MARKER#<taskId>#<columnId>` (get/set specific marker)
- `PK = BOARD#<boardId>, SK begins_with MARKER#<taskId>#` (all markers for a task)
- TransactWriteItems for reorder operations and shiftContext

**Integration Points with Frontend:**
- Deliver schema additions: Column mutations, Task mutations, Marker mutations
- Agree on marker cycling semantics (what the backend returns when cycling to empty: `null` marker)
- Frontend can begin grid rendering, tap-to-cycle, drag-to-reorder

**Test Coverage:**
- Unit tests for all 13 resolvers
- Integration tests for marker cycling, shiftContext atomicity, reorder transactions
- Test concurrent cycleMarker calls (conditional write conflict scenario)
- Minimum 90% line coverage

**Dependencies:**
- DevOps: `dogfood` environment deployed by end of sprint
- Frontend: Board detail screen with grid rendering ready for API integration

---

### Sprint 3 (Weeks 5-6): Templates, Board Creation Flow, Dogfood Hardening

**Lambda Resolvers to Implement:**
- `listTemplates` -- Query `PK = TEMPLATE` for all board templates
- `createBoard` enhancement -- Accept optional `templateId`, clone template columns into new board
- `addTask` enhancement -- Support batch task creation (for template boards with pre-populated tasks)
- Board creation from template -- Transactional creation of board + all template columns in one operation

**DynamoDB Access Patterns:**
- `PK = TEMPLATE, SK begins_with TMPL#` (list all templates)
- TransactWriteItems for board + columns creation from template (up to 25 items per transaction; for monthly boards with 31 columns, use two transactions or BatchWriteItem with retry)

**Integration Points with Frontend:**
- Template selection UI consumes `listTemplates` query
- Frontend begins daily dogfooding on `dogfood` environment
- Collect feedback from dogfood usage to inform Sprint 4 priorities

**Test Coverage:**
- Unit tests for template listing and template-based board creation
- Integration test: create board from weekly template, verify 7 columns created with correct labels
- Fix any bugs surfaced during initial dogfood usage

**Dependencies:**
- DevOps: Seed template data into dogfood DynamoDB table
- DevOps: Dogfood environment stable and accessible
- Frontend: Complete board creation flow with template selection

---

### Sprint 4 (Weeks 7-8): Migration & Sync

**Lambda Resolvers to Implement:**
- `migrateTasks` -- Core migration logic using TransactWriteItems (see Section 4c for full detail)
- `syncBoard` -- Delta sync query returning all items modified since a timestamp
- Conflict resolution Lambda -- Registered as AppSync's conflict handler

**DynamoDB Access Patterns:**
- TransactWriteItems for migration: for each task, 3 writes (update source task state, create migration marker on source, create new task on target). Max 25 items per transaction, so batches of 8 tasks per transaction.
- `PK = BOARD#<boardId>`, FilterExpression `_lastModified >= :timestamp` for delta sync
- Conflict resolver reads both local and remote versions, applies field-level merge

**Integration Points with Frontend:**
- Migration flow UI consumes `migrateTasks` mutation
- Frontend implements delta sync on app foreground/reconnect using `syncBoard`
- Agree on `SyncResult` type structure (updated items, deleted item IDs)
- Frontend implements optimistic conflict resolution client-side for simple cases

**Test Coverage:**
- Unit tests for migrateTasks: happy path, partial failure handling, max task limit
- Integration test: migrate 5 tasks from board A to board B, verify source and target state
- Unit tests for conflict resolution Lambda: same-field conflict, different-field merge, marker last-writer-wins
- Integration test for syncBoard: modify 3 items, sync returns exactly those 3

**Dependencies:**
- DevOps: AppSync conflict resolution Lambda wired in API stack
- Frontend: Migration flow UI ready, sync state machine implemented

---

### Sprint 5 (Weeks 9-10): Subscriptions, Recurring Tasks, EventBridge

**Lambda Resolvers to Implement:**
- Subscription wiring -- Ensure all mutations return `BoardUpdate` payloads compatible with `onBoardUpdated` subscription
- `BoardUpdate` payload construction -- Include `boardId`, `type`, `payload` (JSON-encoded entity), `timestamp`, `deviceId`
- Recurring task Lambda (EventBridge target) -- Evaluate RRULE for all recurring tasks, create new task instances when due
- Migration reminder Lambda (EventBridge target) -- Check boards past their period end date with incomplete tasks, publish reminder (future: push notification via Pinpoint)

**DynamoDB Access Patterns:**
- GSI2: `GSI2PK = USER#<userId>#ACTIVE` to find all active tasks with recurrence rules
- Scan with FilterExpression for recurring tasks due today (or use GSI2 with date-based sort key)
- BatchWriteItem for creating multiple recurring task instances

**Integration Points with Frontend:**
- Frontend subscribes to `onBoardUpdated(boardId)` on board open
- Frontend filters subscription events by `deviceId` (echo suppression)
- Frontend calls `syncBoard` on reconnect after subscription gap
- Agree on subscription payload format and `UpdateType` enum values

**Test Coverage:**
- Unit test for recurring task Lambda: daily recurrence creates task, weekly skips non-due days, RRULE with end date stops creation
- Unit test for subscription payload construction
- Integration test: mutation triggers subscription event with correct payload
- Integration test for migration reminder: board with overdue incomplete tasks triggers event

**Dependencies:**
- DevOps: EventBridge rules configured (daily schedule for recurring tasks, periodic check for migration reminders)
- DevOps: Subscription configuration in AppSync API stack
- Frontend: Subscription handling and reconnection logic

---

### Sprint 6 (Weeks 11-12): Polish, Performance, Production Readiness

**Work Items:**
- Performance optimization (see Section 8): Lambda bundle size audit, cold start measurement, DynamoDB capacity analysis
- Error handling hardening: ensure all resolvers return structured errors (see Section 7)
- API documentation finalization: all queries, mutations, subscriptions documented with examples
- Load testing support: work with QA to provide test data seeding endpoints
- Review and fix all bugs from dogfood usage
- `upcomingDeadlines` query implementation (GSI2-based)
- Pagination hardening for `listBoards` (cursor-based with `nextToken`)

**Test Coverage:**
- Contract tests: validate every resolver response against GraphQL schema types
- Performance benchmarks: measure p50/p95/p99 latency for getBoard, cycleMarker, migrateTasks
- Edge case tests: empty boards, max-size boards (50 tasks x 31 columns = 1550 markers), concurrent mutations

**Dependencies:**
- DevOps: `staging` and `prod` environments deployed
- DevOps: CloudWatch dashboards and alarms configured
- QA: Load test scripts ready (k6/Artillery)
- Frontend: App store submission preparation

---

## 4. Detailed Implementation for Core Backend Operations

### 4a. Board CRUD Resolvers

**Code Structure:**
```
lambda/resolvers/board.ts
  - handler(event: AppSyncResolverEvent)  -- routes by field name
  - createBoard(userId, input) -> Board
  - getBoard(userId, boardId) -> Board | null
  - listBoards(userId, archived, limit, nextToken) -> BoardConnection
  - updateBoard(userId, boardId, input) -> Board
  - archiveBoard(userId, boardId) -> Board
  - deleteBoard(userId, boardId) -> ID
```

**createBoard Logic:**
1. Extract `userId` from `event.identity.sub` (Cognito JWT)
2. Generate `boardId` via `uuid.v4()`
3. Validate input: `name` non-empty (max 100 chars), `type` is valid enum
4. If `templateId` provided, fetch template and clone columns
5. TransactWriteItems:
   - Put board item: `PK=USER#<userId>, SK=BOARD#<boardId>`, `_version=1`, `_lastModified=now`
   - Put each column item: `PK=BOARD#<boardId>, SK=COL#<paddedPosition>#<columnId>`
   - ConditionExpression on board: `attribute_not_exists(PK)` (prevent duplicate)
6. Return assembled Board object

**getBoard Logic:**
1. Verify ownership: Query `GSI1PK=BOARD#<boardId>` to get owner userId, compare with caller
2. Query `PK=BOARD#<boardId>` -- returns ALL items (columns, tasks, markers) in one query
3. Client-side (in Lambda) group items by `_type` discriminator: columns sorted by SK prefix, tasks sorted by SK prefix, markers keyed by `taskId#columnId`
4. Assemble and return the full Board object with nested columns, tasks (each with their markers)

**Authorization Check (all resolvers):**
- Extract `userId` from JWT `sub` claim in `event.identity`
- For board-level operations: verify `PK = USER#<userId>` contains the board
- For sub-board operations (task, column, marker): verify user owns the parent board via GSI1 lookup or by including a `userId` attribute on sub-board items
- Return `UNAUTHORIZED` error if mismatch

**Error Handling:**
- Board not found: return GraphQL error with `errorType: "NOT_FOUND"`
- Validation failure: return `errorType: "VALIDATION_ERROR"` with field-level details
- Version conflict: return `errorType: "CONFLICT"` with current server version
- DynamoDB errors: catch, log, return `errorType: "INTERNAL_ERROR"`

---

### 4b. Marker Operations (setMarker, cycleMarker, shiftContext)

These are the highest-frequency operations -- every tap on the grid triggers one. They must be fast, idempotent, and conflict-safe.

**setMarker:**
1. Validate: taskId exists on the board, columnId exists on the board (can cache board structure in Lambda memory for hot boards)
2. DynamoDB PutItem:
   - `PK=BOARD#<boardId>, SK=MARKER#<taskId>#<columnId>`
   - `data.symbol=<symbol>, data.updatedAt=now`
   - `_version=1` (or increment if exists)
   - `_lastModified=now, _deleted=false`
   - No condition expression -- upsert semantics (idempotent)
3. Return the Marker object

**cycleMarker:**
1. GetItem: `PK=BOARD#<boardId>, SK=MARKER#<taskId>#<columnId>`
2. Determine next symbol: `null->DOT->CIRCLE->X->null`
3. If next is null: DeleteItem (or set `_deleted=true` for sync) with ConditionExpression `_version = :currentVersion`
4. If next is a symbol: PutItem with ConditionExpression `_version = :currentVersion` (or `attribute_not_exists(PK)` for new marker)
5. On `ConditionalCheckFailedException`: re-read item, retry once (another device may have cycled simultaneously)
6. Return the new Marker or null

**shiftContext:**
1. TransactWriteItems (atomic):
   - Delete (or update to X/done) marker at `MARKER#<taskId>#<fromColumnId>`
   - Put marker at `MARKER#<taskId>#<toColumnId>` with `symbol=DOT`
   - Both with `_lastModified=now`
2. ConditionExpression on the source marker: `attribute_exists(PK)` -- fail if marker doesn't exist in the source column
3. On TransactionCanceledException: return error indicating source marker not found or target marker already exists
4. Return both markers (the removed/updated one and the new one)

**DynamoDB Write Patterns for Markers:**
- Write capacity: 1 WCU per marker operation (item < 1KB)
- Read capacity for cycleMarker: 0.5 RCU (eventually consistent GetItem) + 1 WCU
- shiftContext: 2 WCUs (transaction, but each write is < 1KB)

**Optimistic Locking:**
- Every marker carries `_version` (integer, starts at 1)
- On write, ConditionExpression: `_version = :expectedVersion` (or `attribute_not_exists(PK)` for creates)
- On conflict: read latest, retry once. If still conflicting, return CONFLICT error to client
- For markers specifically, last-writer-wins is acceptable because marker state is a simple enum -- there is no meaningful "merge" between two different symbol values

---

### 4c. Migration Resolver (migrateTasks)

**Input:** `sourceBoardId`, `targetBoardId`, `taskIds[]`

**Logic:**
1. Validate ownership of both source and target boards
2. Validate all taskIds exist on the source board and are in a migratable state (OPEN or IN_PROGRESS, not already MIGRATED/COMPLETE/CANCELLED)
3. Group tasks into batches of 8 (each task requires 3 DynamoDB writes; TransactWriteItems max is 25 items)
4. For each batch, execute TransactWriteItems:
   - **Update source task**: Set `state=MIGRATED`, `_version++`, `_lastModified=now`
   - **Put migration marker on source**: `PK=BOARD#<sourceBoardId>, SK=MARKER#<taskId>#<migrationColumnId>`, `symbol=MIGRATED`
   - **Put new task on target**: `PK=BOARD#<targetBoardId>, SK=TASK#<newPosition>#<newTaskId>`, copy title/description/priority/deadline, set `state=OPEN`, `migratedFromBoardId=sourceBoardId`, `migratedFromTaskId=taskId`
5. Return `MigrationResult` with count and updated board summaries

**Atomicity Guarantees:**
- Each batch of 8 tasks is atomic (single TransactWriteItems call)
- If a batch fails (e.g., ConditionalCheckFailed on one task), the entire batch rolls back
- Cross-batch atomicity is NOT guaranteed. If batch 1 succeeds and batch 2 fails, batch 1's changes persist.

**Handling Partial Failures:**
- Track which batches succeeded in the response
- Return a `MigrationResult` that includes `migratedCount` (actual), `failedTaskIds[]`, and an error message for the failed batch
- The client can retry failed tasks
- The migration is idempotent: migrating an already-migrated task is a no-op (ConditionExpression `state IN (OPEN, IN_PROGRESS)`)

**Audit Trail:**
- Every migrated task on the target board carries `migratedFromBoardId` and `migratedFromTaskId`
- The source task's state is `MIGRATED` with a `MIGRATED` symbol marker
- This creates a bidirectional link: from the target task you can trace back to the source, and from the source task you can see it was migrated

---

### 4d. Sync & Conflict Resolution

**Delta Sync Query Design:**

`syncBoard(boardId, lastSyncTimestamp)`:
1. Query `PK = BOARD#<boardId>` with FilterExpression `_lastModified >= :lastSyncTimestamp`
2. Return all matching items (columns, tasks, markers) including soft-deleted items (`_deleted = true`)
3. The client applies these changes to its local cache: upsert modified items, remove deleted items

Note: FilterExpression is applied after the read, so the full partition is read and then filtered. For boards with < 200 items this is fine (well under 1MB). For very large boards, consider a GSI with `_lastModified` as the sort key, but this is premature optimization.

**Response Structure (`SyncResult`):**
```graphql
type SyncResult {
  items: [SyncItem!]!
  lastSyncTimestamp: AWSDateTime!
}

type SyncItem {
  type: String!        # COLUMN | TASK | MARKER
  action: SyncAction!  # UPSERT | DELETE
  data: String!        # JSON-encoded entity
  version: Int!
}
```

**Version-Based Conflict Detection:**
- Every entity has `_version` (integer, incremented on every write)
- AppSync's built-in conflict detection compares the client's `_version` with the server's `_version`
- If they differ, the conflict resolution Lambda is invoked

**Conflict Resolution Lambda:**

```
lambda/resolvers/sync.ts
  - conflictHandler(event: ConflictResolutionEvent)
    - event contains: { existingItem, newItem, entityType }
```

Resolution rules:
- **Markers**: Last-writer-wins. Compare `_lastModified` timestamps. The newer one wins. Rationale: marker state is a single enum value; there's no meaningful merge between `DOT` and `CIRCLE`.
- **Tasks**: Field-level merge. Compare each changed field between the two versions:
  - If only one side changed a field, take that change
  - If both sides changed the same field, last-writer-wins by `_lastModified`
  - Fields eligible for merge: `title`, `description`, `state`, `priority`, `deadline`, `position`
  - The `_version` on the merged result is `max(existing._version, new._version) + 1`
- **Columns**: Last-writer-wins (column edits are rare and low-conflict)
- **Boards**: Last-writer-wins (board metadata edits are rare)

**Tombstones (Handling Deleted Items):**
- Deleted items are not physically removed. Instead: `_deleted = true`, `_lastModified = now`
- Delta sync includes deleted items so clients can remove them from local cache
- A scheduled cleanup Lambda (weekly) physically deletes items where `_deleted = true` AND `_lastModified < now - 30 days`
- This 30-day window ensures all devices have time to sync the deletion

---

### 4e. Real-Time Subscriptions

**AppSync Subscription Wiring:**
- The `onBoardUpdated(boardId)` subscription is triggered by all board-modifying mutations
- Each mutation resolver returns a `BoardUpdate` object that AppSync broadcasts to subscribers
- Enhanced subscription filtering ensures only clients subscribed to the specific `boardId` receive events

**BoardUpdate Payload Construction (in each resolver):**
```typescript
function buildBoardUpdate(
  boardId: string,
  type: UpdateType,  // MARKER_SET | MARKER_REMOVED | TASK_ADDED | TASK_UPDATED | ...
  entity: any,
  deviceId: string
): BoardUpdate {
  return {
    boardId,
    type,
    payload: JSON.stringify(entity),
    timestamp: new Date().toISOString(),
    deviceId,
  };
}
```

**Device Echo Suppression:**
- Every mutation request includes a `deviceId` header (passed through AppSync request mapping)
- The `BoardUpdate` payload includes this `deviceId`
- The frontend client compares `BoardUpdate.deviceId` with its own deviceId; if they match, the event is discarded
- This is a client-side responsibility, but the backend must ensure `deviceId` flows through correctly

**Reconnection Catch-up:**
- When a subscription disconnects and reconnects, the client calls `syncBoard(boardId, lastKnownTimestamp)` to fetch any changes missed during the gap
- The backend's delta sync query handles this transparently
- The client must track the timestamp of the last received subscription event or last successful sync

---

### 4f. Recurring Task Engine

**EventBridge Scheduled Rule:**
- Rule: fires daily at 00:05 UTC (just after midnight to catch daily recurrences)
- Target: `recurring-task-lambda`

**Lambda Logic:**
1. Query GSI2 for all active recurring tasks: `GSI2PK begins_with USER#` with FilterExpression `data.recurring = true`
   - Alternative: maintain a separate `PK=RECURRING, SK=TASK#<taskId>` index for efficient scanning
2. For each recurring task, evaluate the RRULE against today's date using the `rrule` library
3. If today matches the recurrence pattern AND no task instance exists for today:
   - Create a new task on the appropriate board with `state=OPEN`
   - Link back to the recurring template via `recurringSourceTaskId`
4. Use BatchWriteItem for efficient bulk creation (up to 25 items per batch)

**RRULE Evaluation:**
- Parse the `recurrenceRule` string (e.g., `FREQ=WEEKLY;BYDAY=MO,WE,FR`)
- Use the `rrule` library to check if today falls within the recurrence pattern
- Handle edge cases: recurrence end date, exception dates, timezone considerations

**Error Scenarios:**
- Target board archived or deleted: skip task creation, log warning
- RRULE parse failure: log error, skip this task, continue processing others
- DynamoDB throttling: retry with exponential backoff (handled by SDK)
- Lambda timeout: the rule fires daily, so missed tasks will be created the next day (idempotency check prevents duplicates)

---

## 5. API Contract Documentation

### Schema as the Contract

The GraphQL schema file (`schema/schema.graphql`) is the single source of truth for the API contract between frontend and backend. Both teams reference this file.

### Schema Evolution Strategy

1. **Additive-only changes**: New fields, new types, new enum values are added without breaking existing clients. This is the default approach for all schema changes.

2. **Deprecation policy**:
   - Fields are deprecated with `@deprecated(reason: "Use newField instead")` directive
   - Deprecated fields continue to function for a minimum of 2 sprints (4 weeks)
   - After 2 sprints, deprecated fields are removed only after verifying no client usage via AppSync CloudWatch metrics
   - Breaking changes (field removal, type changes) require a coordinated release with frontend

3. **Schema change process**:
   - Backend engineer proposes schema changes in a PR modifying `schema/schema.graphql`
   - Frontend engineer reviews and approves (or requests changes)
   - CI runs contract tests validating both backend responses and frontend codegen against the schema
   - Schema changes merge to `main` only with both backend and frontend approval

4. **Versioning**: No API versioning. Additive-only changes eliminate the need. If a fundamental restructuring is ever needed, a new AppSync API is created alongside the old one (extremely unlikely for this application).

### Coordination Workflow

- Backend and frontend engineers review schema PRs together
- Frontend runs client codegen (`graphql_codegen` or `artemis` for Dart) on every schema change
- Any codegen failure blocks the schema PR

---

## 6. Data Access Patterns

### 6.1 Loading a Full Board

**Operation:** Query
```
Table: alpha-{stage}-main
Key condition: PK = "BOARD#<boardId>"
No sort key condition (returns all items under this partition)
```

**Projection:** All attributes (columns, tasks, and markers have different attribute shapes; projecting specific attributes would require knowing the entity type in advance)

**Expected items:** For a typical weekly board: 1 board metadata (from GSI1, or skip if already known) + 7 columns + 15-30 tasks + 50-100 markers = ~75-140 items

**Consumed capacity:** ~15-30 RCUs (eventually consistent, ~70KB of data at 4KB per RCU)

**Post-processing in Lambda:**
```typescript
const items = queryResult.Items;
const columns = items.filter(i => i._type === 'COLUMN').sort(bySK);
const tasks = items.filter(i => i._type === 'TASK').sort(bySK);
const markers = items.filter(i => i._type === 'MARKER');
// Group markers by taskId for nesting
const markersByTask = groupBy(markers, m => m.data.taskId);
// Assemble response
```

### 6.2 Reordering Tasks

**Operation:** TransactWriteItems

When task C moves from position 3 to position 1 (positions: A=1, B=2, C=3, D=4):

```
TransactWriteItems:
  - Delete: PK=BOARD#<boardId>, SK=TASK#0003#<taskCId>
  - Put:    PK=BOARD#<boardId>, SK=TASK#0001#<taskCId>, (all task C data with updated position)
  - Delete: PK=BOARD#<boardId>, SK=TASK#0001#<taskAId>
  - Put:    PK=BOARD#<boardId>, SK=TASK#0002#<taskAId>, (all task A data with updated position)
  - Delete: PK=BOARD#<boardId>, SK=TASK#0002#<taskBId>
  - Put:    PK=BOARD#<boardId>, SK=TASK#0003#<taskBId>, (all task B data with updated position)
```

Each reposition requires a delete + put (SK contains position, so changing position = changing SK = new item). This consumes 6 WCUs for 3 tasks. For reordering N tasks: 2N write operations in one transaction (max 12 tasks per transaction given the 25-item limit).

**Alternative approach (gap-based positioning):** Use floating-point or large-integer positions with gaps (e.g., 1000, 2000, 3000). Moving C between A and B sets C's position to 1500. No other items need updating. Re-gap only when gaps become too small. This reduces writes from O(N) to O(1) for most reorders. Recommended as an optimization in Sprint 6.

### 6.3 Delta Sync

**Operation:** Query with FilterExpression

```
Table: alpha-{stage}-main
Key condition: PK = "BOARD#<boardId>"
Filter expression: _lastModified >= :lastSyncTimestamp
Expression attribute values: { ":lastSyncTimestamp": "2026-03-15T10:30:00.000Z" }
```

**Note:** The filter is applied after the query reads all items in the partition. The full partition is consumed in terms of RCUs, but only matching items are returned over the network. For boards under 200 items (~100KB), this is efficient. The cost is the same as loading the full board.

**Consumed capacity:** Same as full board load (~15-30 RCUs) regardless of how many items actually changed.

**Optimization for large boards:** If boards grow beyond 500 items, add a LSI or GSI with `_lastModified` as the sort key. Not needed for the initial launch.

---

## 7. Error Handling Strategy

### Error Taxonomy

| Error Type | HTTP-Equivalent | When | Retry? |
|-----------|----------------|------|--------|
| `VALIDATION_ERROR` | 400 | Invalid input (empty title, bad enum, exceeds limits) | No -- fix input |
| `NOT_FOUND` | 404 | Board/task/column/marker does not exist | No |
| `UNAUTHORIZED` | 403 | User does not own the requested resource | No |
| `CONFLICT` | 409 | Version mismatch (optimistic locking failure) | Yes -- re-read and retry |
| `RATE_LIMITED` | 429 | DynamoDB throttling or AppSync rate limit | Yes -- with backoff |
| `INTERNAL_ERROR` | 500 | Unexpected DynamoDB error, Lambda failure, bug | Yes -- with backoff |

### Error Response Format

All errors are returned as GraphQL errors with structured `extensions`:

```json
{
  "errors": [
    {
      "message": "Task not found",
      "errorType": "NOT_FOUND",
      "path": ["completeTask"],
      "extensions": {
        "code": "NOT_FOUND",
        "entityType": "Task",
        "entityId": "abc-123",
        "retryable": false
      }
    }
  ]
}
```

For `CONFLICT` errors, include the current server state:

```json
{
  "extensions": {
    "code": "CONFLICT",
    "currentVersion": 5,
    "currentState": { ... },
    "retryable": true
  }
}
```

### How Errors Surface to Frontend

- Frontend GraphQL client (e.g., `graphql_flutter` or `ferry`) parses `errorType` from the response
- `VALIDATION_ERROR`: display field-level error messages to user
- `NOT_FOUND`: navigate away from deleted resource, show toast
- `UNAUTHORIZED`: redirect to login
- `CONFLICT`: re-fetch entity, re-apply user's change, retry mutation
- `RATE_LIMITED`: automatic retry with exponential backoff (SDK-level)
- `INTERNAL_ERROR`: show generic error message, log to crash reporting

### Retry Guidance

| Error | Client behavior |
|-------|----------------|
| `CONFLICT` | Re-read entity, merge changes, retry mutation with new version |
| `RATE_LIMITED` | Retry after 1s, 2s, 4s (exponential backoff, max 3 retries) |
| `INTERNAL_ERROR` | Retry once after 2s. If still failing, surface error to user |
| All others | Do not retry |

---

## 8. Performance Optimization

### 8.1 DynamoDB Read/Write Optimization

- **Single-table design** ensures full board loads in one Query (no joins, no N+1)
- **Eventually consistent reads** by default (half the RCU cost). Use strongly consistent only for conflict resolution reads.
- **Projection expressions** on queries where full attributes aren't needed (e.g., `listBoards` only needs board metadata, not all sub-items -- but this is already partitioned by `USER#<userId>`)
- **Gap-based positioning** (Sprint 6) reduces reorder writes from O(N) to O(1)
- **BatchGetItem** for targeted multi-item reads (e.g., validating multiple taskIds exist before migration)

### 8.2 Lambda Cold Start Mitigation

| Strategy | Impact | Sprint |
|----------|--------|--------|
| **ARM64 (Graviton2)** | 20% cost reduction, ~10% faster cold starts | Sprint 1 (configure in CDK) |
| **esbuild tree-shaking** | Bundle size < 500KB (vs 5MB+ without tree-shaking) | Sprint 1 |
| **Externalize AWS SDK** | SDK v3 is pre-installed in Lambda runtime; excluding it from bundle reduces size by 2-3MB | Sprint 1 |
| **Lambda Layers** | Shared code (types, DynamoDB client wrapper) in a layer, reused across functions | Sprint 2 |
| **Single-purpose functions vs. monolith** | Trade-off: many small functions = more cold starts but smaller bundles. Recommendation: group by entity (one function for all board resolvers, one for all marker resolvers) | Sprint 1 |
| **Provisioned Concurrency** | Eliminates cold starts entirely. Only if cold starts degrade UX in dogfood. Measure first. | Sprint 6 (if needed) |

**Target cold start:** < 300ms (ARM64 + esbuild + small bundle)
**Target warm invocation:** < 50ms (simple DynamoDB operation)

### 8.3 AppSync Caching

- **Per-resolver caching** enabled for read-heavy queries:
  - `listTemplates`: cache 1 hour (templates rarely change)
  - `getBoard`: cache 60s in dogfood, 300s in prod (with invalidation on mutation)
  - `listBoards`: cache 30s (new boards are infrequent)
- **No caching** on mutations or sync queries
- Cache key: based on query arguments + user identity

### 8.4 Batch Operations

- **BatchWriteItem** for template-based board creation (> 25 columns)
- **BatchGetItem** for migration validation (check multiple task IDs exist)
- **TransactWriteItems** for atomic multi-item writes (reorder, shiftContext, migrate)
- Unprocessed items from batch operations are retried with exponential backoff

---

## 9. Collaboration Points

### 9.1 With Software Engineer (Frontend)

| Touchpoint | Cadence | Artifact |
|-----------|---------|----------|
| **API contract review** | Every PR modifying schema | PR review on `schema/schema.graphql` |
| **Subscription event format** | Sprint 5, then as needed | `BoardUpdate` type definition and `UpdateType` enum |
| **Sync protocol agreement** | Sprint 4 | Document: "how delta sync works, what SyncResult contains, when to call syncBoard" |
| **Error handling contract** | Sprint 1 | Document: error taxonomy, response format, retry guidance (Section 7 of this plan) |
| **Sprint demos** | End of each sprint | Backend demonstrates API via GraphQL playground; frontend demonstrates UI consuming the API |
| **Dogfood bug triage** | Daily during Sprint 3+ | Shared issue tracker; determine if bug is frontend or backend |

### 9.2 With QA Engineer

| Touchpoint | Cadence | Artifact |
|-----------|---------|----------|
| **API test environment** | Sprint 1 setup | `dev` environment AppSync endpoint + Cognito credentials for test user |
| **Test data seeding** | Sprint 3 | Seeding script or Lambda endpoint that creates boards/tasks/markers for test scenarios |
| **Contract test maintenance** | Every schema change | Backend updates contract tests; QA reviews coverage |
| **Load test collaboration** | Sprint 6 | Backend provides target latency SLAs; QA writes and runs load test scripts |
| **Bug reproduction** | As needed | Backend provides CloudWatch log queries for specific request IDs |

### 9.3 With DevOps Engineer

| Touchpoint | Cadence | Artifact |
|-----------|---------|----------|
| **Lambda deployment config** | Sprint 1, then as needed | Backend specifies: runtime (Node 20), architecture (ARM64), memory (256MB), timeout (10s), handler path |
| **Environment variables** | Sprint 1 | Backend specifies required env vars: `TABLE_NAME`, `STAGE`, `DYNAMODB_ENDPOINT` (local only) |
| **IAM permissions needed** | Sprint 1, then as needed | Backend specifies DynamoDB actions per Lambda: `GetItem`, `PutItem`, `Query`, `TransactWriteItems`, etc. DevOps creates least-privilege policies |
| **EventBridge rules** | Sprint 5 | Backend specifies schedule expressions and target Lambdas; DevOps wires in CDK |
| **AppSync resolver mapping** | Sprint 1, then as needed | Backend specifies which Lambda handles which GraphQL field; DevOps configures in AppSync CDK construct |
| **Monitoring requirements** | Sprint 6 | Backend specifies key metrics and alarm thresholds; DevOps configures dashboards |

---

## 10. Testing Responsibilities

### What Backend Engineer Writes

| Test Type | Scope | Tool | Coverage Target |
|-----------|-------|------|----------------|
| **Unit tests** | Every Lambda resolver function, isolated with mocked DynamoDB client | Jest + ts-jest | 90% lines, 85% branches |
| **Integration tests** | Resolver functions against DynamoDB Local, verifying actual read/write behavior | Jest + DynamoDB Local (Docker) | All access patterns exercised |
| **Contract tests** | Validate every resolver response conforms to GraphQL schema types; validate error response format | Jest + schema validation | Every resolver, every error type |
| **Conflict resolution tests** | Unit tests for the conflict resolution Lambda covering all entity types and merge scenarios | Jest | Every merge rule |

**Test naming convention:** `[resolver] [condition] [expected behavior]`
- `createBoard with valid input should return board with generated ID and version 1`
- `cycleMarker when marker is X should delete marker and return null`
- `migrateTasks when task is already COMPLETE should skip task and not error`
- `conflictHandler when both sides change different task fields should merge both changes`

### What QA Engineer Writes

| Test Type | Scope | Tool |
|-----------|-------|------|
| **E2E API tests** | Full request lifecycle through AppSync (auth, resolver, DynamoDB, response) against staging | Playwright / custom GraphQL client |
| **Load tests** | Concurrent user simulation: marker toggles, board loads, migrations | k6 or Artillery |
| **Smoke tests** | Read-only checks against prod after deployment (can I list boards? can I load a board?) | Custom script |
| **Cross-device sync tests** | Two clients, one board: verify mutation on client A appears on client B | Custom test harness |

### Shared Testing

- **Contract tests** are maintained by backend but reviewed by both frontend and QA
- **Test data fixtures** (JSON files for boards, tasks, markers) are shared between backend integration tests and frontend widget tests
- **Seeding scripts** are written by backend but used by QA for E2E test setup

---

### Critical Files for Implementation

- `/Users/alastairdrong/wip/AlPHA/docs/infra/aws-backend.md` - Authoritative architecture reference: DynamoDB key patterns, GraphQL schema, phased delivery plan, all access patterns
- `/Users/alastairdrong/wip/AlPHA/docs/the-alastair-method.md` - Product domain specification: task state machine, marker cycling rules, migration semantics, context shifting logic
- `/Users/alastairdrong/wip/AlPHA/docs/app/plan-testing-strategy.md` - Testing contracts: coverage thresholds, CI pipeline structure, test environment matrix, load test SLAs
- `infra/lambda/resolvers/marker.ts` (to be created) - Highest-frequency resolver: setMarker, cycleMarker, shiftContext with conditional writes and optimistic locking
- `infra/lambda/resolvers/migration.ts` (to be created) - Most complex resolver: TransactWriteItems batching, partial failure handling, cross-board atomicity, audit trail