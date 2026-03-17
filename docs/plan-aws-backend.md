# AlPHA Backend Development Plan

## AWS Backend Architecture for the Alastair Planner & Habit App

---

## 1. Architecture Overview

### Decision: Serverless-First with GraphQL

**API Style: AWS AppSync (GraphQL)**

GraphQL is the correct choice for AlPHA for three structural reasons:

1. **The grid is a deeply nested object graph.** A single board view requires the board, its columns, its tasks, and every marker at each task-column intersection. With REST, this would require either over-fetching (fat endpoints) or under-fetching (N+1 waterfalls). A single GraphQL query like `board(id) { columns { ... } tasks { markers { ... } } }` resolves the entire view in one round-trip.

2. **Offline-first sync requires conflict-aware mutations.** AppSync has built-in offline support with configurable conflict resolution (version-based, auto-merge, or custom Lambda). This directly addresses the multi-device sync requirement.

3. **Real-time subscriptions are native.** AppSync subscriptions over WebSockets deliver marker changes, task additions, and board updates to all connected devices without additional infrastructure.

**Compute: AWS Lambda**

All resolver logic runs in Lambda functions. The workloads are short-lived request-response operations (CRUD, migration logic, conflict resolution) -- precisely what Lambda is designed for. There is no long-running compute that would justify containers.

**Why not REST + API Gateway + Lambda:**
- REST would require dozens of endpoints to cover the board/task/marker matrix, plus custom WebSocket infrastructure for real-time sync.
- AppSync provides the API layer, auth integration, caching, subscriptions, and offline support in a single managed service.

---

## 2. AWS Services

| Layer | Service | Purpose |
|-------|---------|---------|
| **API** | AWS AppSync | GraphQL API with subscriptions, offline sync, caching |
| **Compute** | AWS Lambda | Resolver logic, migration workflows, scheduled jobs |
| **Database** | Amazon DynamoDB | Primary data store (single-table design) |
| **Auth** | Amazon Cognito | User pools, JWT tokens, multi-device sessions |
| **Storage** | Amazon S3 | Board export files, user profile images, static assets |
| **CDN** | Amazon CloudFront | Frontend distribution, S3 asset delivery |
| **Messaging** | Amazon EventBridge | Async events: migration reminders, recurring task creation |
| **Monitoring** | Amazon CloudWatch | Logs, metrics, alarms, dashboards |
| **Secrets** | AWS Secrets Manager | API keys, third-party credentials |
| **IaC** | AWS CDK (TypeScript) | Infrastructure definition and deployment |

### Services explicitly NOT used

- **Aurora/RDS**: The access patterns are key-value and document-oriented, not relational. DynamoDB is cheaper, faster, and scales without capacity management.
- **ECS/Fargate**: No long-running or stateful compute requirements.
- **SQS**: EventBridge handles async event routing with richer filtering; SQS would only be used if dead-letter queuing for specific Lambda failures is needed (EventBridge supports DLQs natively).

---

## 3. Data Model

### 3.1 DynamoDB Single-Table Design

A single DynamoDB table serves all entities. This is the standard approach for serverless applications with known access patterns, enabling all queries to hit a single table with predictable performance.

**Table: `alpha-{stage}-main`**

| Attribute | Type | Description |
|-----------|------|-------------|
| `PK` | String | Partition key |
| `SK` | String | Sort key |
| `GSI1PK` | String | GSI1 partition key |
| `GSI1SK` | String | Sort key for GSI1 |
| `GSI2PK` | String | GSI2 partition key |
| `GSI2SK` | String | Sort key for GSI2 |
| `_type` | String | Entity type discriminator |
| `_version` | Number | Optimistic locking / conflict detection |
| `_lastModified` | String | ISO 8601 timestamp for sync |
| `_deleted` | Boolean | Soft-delete flag for sync |
| `data` | Map | Entity-specific attributes |

### 3.2 Entity Key Patterns

#### User
```
PK: USER#<userId>
SK: USER#<userId>
GSI1PK: EMAIL#<email>
GSI1SK: USER#<userId>
data: { displayName, email, preferences, createdAt }
```

#### Board
```
PK: USER#<userId>
SK: BOARD#<boardId>
GSI1PK: BOARD#<boardId>
GSI1SK: BOARD#<boardId>
data: { name, type (DAILY|WEEKLY|MONTHLY|YEARLY|CUSTOM), archived, createdAt }
```

#### Column
```
PK: BOARD#<boardId>
SK: COL#<position>#<columnId>
data: { label, type (TIME_PERIOD|CONTEXT|CUSTOM), color, position }
```

#### Task
```
PK: BOARD#<boardId>
SK: TASK#<position>#<taskId>
GSI2PK: USER#<userId>#ACTIVE
GSI2SK: <deadline|createdAt>
data: { title, description, state (OPEN|IN_PROGRESS|COMPLETE|MIGRATED|CANCELLED),
        priority, deadline, recurring, recurrenceRule, createdAt, completedAt,
        migratedFromBoardId, migratedFromTaskId }
```

#### Marker
```
PK: BOARD#<boardId>
SK: MARKER#<taskId>#<columnId>
data: { symbol (DOT|X|CIRCLE|STAR|TILDE|MIGRATED), createdAt, updatedAt }
```

#### Board Template
```
PK: TEMPLATE
SK: TMPL#<templateId>
data: { name, type, columns: [{ label, type, color }] }
```

### 3.3 Access Patterns

| Access Pattern | Key Condition | Index |
|----------------|--------------|-------|
| Get all boards for a user | `PK = USER#<userId>`, `SK begins_with BOARD#` | Main table |
| Get board with all columns, tasks, markers | `PK = BOARD#<boardId>` | Main table (returns columns, tasks, markers in one query) |
| Get a single board's metadata | `GSI1PK = BOARD#<boardId>`, `GSI1SK = BOARD#<boardId>` | GSI1 |
| Get user by email | `GSI1PK = EMAIL#<email>` | GSI1 |
| Get active tasks with upcoming deadlines | `GSI2PK = USER#<userId>#ACTIVE`, `GSI2SK <= <date>` | GSI2 |
| Get all markers for a task | `PK = BOARD#<boardId>`, `SK begins_with MARKER#<taskId>#` | Main table |
| Get all templates | `PK = TEMPLATE` | Main table |
| Sync: get all items modified since timestamp | `PK = BOARD#<boardId>`, filter `_lastModified >= <ts>` | Main table |

### 3.4 Why this layout works for the Alastair Method

The critical query is "load an entire board" -- the user opens a board and needs columns, tasks, and every marker rendered as a grid. With `PK = BOARD#<boardId>`, a single Query returns all columns (`SK begins_with COL#`), all tasks (`SK begins_with TASK#`), and all markers (`SK begins_with MARKER#`) in one read. The client groups them client-side. For a board with 30 tasks, 7 columns, and 100 markers, this is roughly 140 items -- well within DynamoDB's 1MB per query limit.

Position-based sort keys (`COL#0001#<id>`, `TASK#0005#<id>`) allow ordered retrieval without a secondary sort step. Reordering a task means updating its sort key prefix (a delete + put operation within a transaction).

---

## 4. API Design

### 4.1 GraphQL Schema (Core Types)

```graphql
type Board {
  id: ID!
  name: String!
  type: BoardType!
  archived: Boolean!
  createdAt: AWSDateTime!
  columns: [Column!]!
  tasks: [Task!]!
}

enum BoardType { DAILY WEEKLY MONTHLY YEARLY CUSTOM }

type Column {
  id: ID!
  boardId: ID!
  label: String!
  position: Int!
  color: String
  type: ColumnType!
}

enum ColumnType { TIME_PERIOD CONTEXT CUSTOM }

type Task {
  id: ID!
  boardId: ID!
  title: String!
  description: String
  position: Int!
  state: TaskState!
  priority: Priority!
  deadline: AWSDate
  recurring: Boolean!
  recurrenceRule: String
  createdAt: AWSDateTime!
  completedAt: AWSDateTime
  markers: [Marker!]!
}

enum TaskState { OPEN IN_PROGRESS COMPLETE MIGRATED CANCELLED }
enum Priority { NONE LOW MEDIUM HIGH DEADLINE }

type Marker {
  id: ID!
  taskId: ID!
  columnId: ID!
  symbol: MarkerSymbol!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

enum MarkerSymbol { DOT X CIRCLE STAR TILDE MIGRATED }
```

### 4.2 Queries

```graphql
type Query {
  # Load a full board (columns + tasks + markers in one call)
  getBoard(id: ID!): Board

  # List all boards for the authenticated user
  listBoards(archived: Boolean, limit: Int, nextToken: String): BoardConnection!

  # Get available board templates
  listTemplates: [BoardTemplate!]!

  # Delta sync: fetch changes since a timestamp
  syncBoard(boardId: ID!, lastSyncTimestamp: AWSDateTime!): SyncResult!

  # Active tasks across all boards with deadlines
  upcomingDeadlines(limit: Int): [Task!]!
}
```

### 4.3 Mutations

```graphql
type Mutation {
  # Board operations
  createBoard(input: CreateBoardInput!): Board!
  updateBoard(id: ID!, input: UpdateBoardInput!): Board!
  archiveBoard(id: ID!): Board!
  deleteBoard(id: ID!): ID!

  # Column operations
  addColumn(boardId: ID!, input: AddColumnInput!): Column!
  updateColumn(id: ID!, input: UpdateColumnInput!): Column!
  removeColumn(id: ID!): ID!
  reorderColumns(boardId: ID!, columnIds: [ID!]!): [Column!]!

  # Task operations
  addTask(boardId: ID!, input: AddTaskInput!): Task!
  updateTask(id: ID!, input: UpdateTaskInput!): Task!
  completeTask(id: ID!): Task!
  cancelTask(id: ID!): Task!
  reorderTasks(boardId: ID!, taskIds: [ID!]!): [Task!]!

  # Marker operations (the core interaction)
  setMarker(taskId: ID!, columnId: ID!, symbol: MarkerSymbol!): Marker!
  removeMarker(taskId: ID!, columnId: ID!): ID!
  cycleMarker(taskId: ID!, columnId: ID!): Marker  # Returns null if cycled to empty

  # Context shifting (atomic: remove from one column, add to another)
  shiftContext(taskId: ID!, fromColumnId: ID!, toColumnId: ID!): [Marker!]!

  # Migration (batch operation)
  migrateTasks(input: MigrateTasksInput!): MigrationResult!
}

input MigrateTasksInput {
  sourceBoardId: ID!
  targetBoardId: ID!
  taskIds: [ID!]!
}

type MigrationResult {
  migratedCount: Int!
  sourceBoard: Board!
  targetBoard: Board!
}
```

### 4.4 Subscriptions

```graphql
type Subscription {
  # Real-time board updates (markers, tasks, columns)
  onBoardUpdated(boardId: ID!): BoardUpdate
    @aws_subscribe(mutations: [
      "setMarker", "removeMarker", "cycleMarker",
      "addTask", "updateTask", "completeTask",
      "addColumn", "updateColumn", "removeColumn"
    ])
}

type BoardUpdate {
  boardId: ID!
  type: UpdateType!
  payload: String!  # JSON-encoded entity
  timestamp: AWSDateTime!
  deviceId: String!  # Originating device (for echo suppression)
}
```

### 4.5 Migration Flow (Server-Side Logic)

The `migrateTasks` mutation executes within a DynamoDB transaction:

1. For each selected task in the source board:
   - Set `state = MIGRATED` on the source task
   - Create a `MIGRATED` symbol marker on the source task
   - Create a new task in the target board with `state = OPEN`
   - Copy relevant markers as `DOT` symbols to the new board's equivalent columns
   - Record `migratedFromBoardId` and `migratedFromTaskId` for audit trail
2. Return the updated source and target boards

### 4.6 Offline Sync Protocol

AppSync's built-in offline capabilities handle the common case. The sync strategy:

1. **Optimistic UI**: Mutations are applied locally immediately.
2. **Queue**: When offline, mutations queue in the AppSync client cache.
3. **Replay**: On reconnection, queued mutations replay in order.
4. **Conflict detection**: Each entity carries a `_version` field. AppSync detects version mismatches on write.
5. **Conflict resolution**: A Lambda function resolves conflicts:
   - **Markers**: Last-writer-wins (marker state is idempotent -- a symbol is a symbol).
   - **Tasks**: Field-level merge. If device A changes `title` and device B changes `state`, both changes apply. If both change the same field, last-writer-wins with timestamp comparison.
   - **Reordering**: Last-writer-wins for position changes.
6. **Delta sync query**: `syncBoard(boardId, lastSyncTimestamp)` returns all items with `_lastModified >= timestamp`, including soft-deleted items (so the client can remove them locally).

---

## 5. Authentication & Authorization

### 5.1 Amazon Cognito Configuration

**User Pool:**
- Sign-up with email + password
- Optional social providers (Google, Apple) via Cognito Identity Pool federation
- Email verification required
- Password policy: minimum 8 characters, require mixed case + number
- MFA: optional TOTP (user-enabled in settings)

**App Client:**
- Token expiration: access token 1 hour, refresh token 30 days
- No client secret (public mobile/web client)

### 5.2 JWT Flow

```
Client                    Cognito                   AppSync
  |                         |                         |
  |-- SignUp/SignIn ------->|                         |
  |<-- accessToken,        |                         |
  |    refreshToken,       |                         |
  |    idToken ------------|                         |
  |                         |                         |
  |-- GraphQL request + Authorization: Bearer <accessToken> -->|
  |                         |                         |-- validate JWT
  |                         |                         |-- extract userId (sub claim)
  |                         |                         |-- execute resolver
  |<-- response ------------------------------------------|
  |                         |                         |
  |-- (token expired) ---->|                         |
  |-- refresh request ---->|                         |
  |<-- new accessToken ----|                         |
```

### 5.3 Authorization Rules

AppSync resolvers enforce ownership:

- **Boards**: A user can only access boards where `PK = USER#<their-userId>`. The resolver extracts `userId` from the JWT `sub` claim and constructs the partition key.
- **Board contents**: Since columns, tasks, and markers live under `PK = BOARD#<boardId>`, the resolver first verifies the user owns the board (via GSI1 lookup or cached ownership check).
- **Templates**: Read-only for all authenticated users.

### 5.4 Multi-Device Support

- Cognito refresh tokens support concurrent sessions across devices.
- Each device registers a `deviceId` (UUID generated on first app launch, stored locally).
- The `deviceId` is sent with every mutation and included in subscription payloads, allowing clients to suppress echoes of their own changes.
- Token refresh is handled by the AppSync client SDK automatically.

---

## 6. Real-Time Sync

### 6.1 AppSync Subscriptions (WebSockets)

AppSync manages WebSocket connections natively. When a client opens a board:

1. Client subscribes to `onBoardUpdated(boardId: "<id>")`.
2. Any mutation on that board triggers a subscription event to all connected clients.
3. The payload includes the `deviceId` of the originator; clients ignore their own events.

### 6.2 Connection Lifecycle

- **Connect**: On board open, client establishes subscription.
- **Reconnect**: AppSync client SDK handles automatic reconnection with exponential backoff.
- **Disconnect**: On board close or app background, subscription is torn down.
- **Catch-up**: On reconnect, the client runs `syncBoard()` with its last-known timestamp to fetch any changes missed during disconnection.

### 6.3 Subscription Filtering

AppSync enhanced subscription filtering ensures clients only receive events for boards they are viewing. This prevents unnecessary data transfer for users with many boards.

---

## 7. Infrastructure as Code

### 7.1 Decision: AWS CDK (TypeScript)

**Why CDK over Terraform:**

- The entire backend is AWS-native (no multi-cloud requirement).
- CDK L2/L3 constructs for AppSync, DynamoDB, Lambda, and Cognito reduce boilerplate significantly.
- TypeScript CDK aligns with a TypeScript Lambda runtime, allowing shared types between infrastructure and application code.
- CDK Pipelines provides built-in CI/CD with multi-environment deployment.

### 7.2 Project Structure

```
infra/
├── bin/
│   └── alpha-app.ts              # CDK app entry point
├── lib/
│   ├── stacks/
│   │   ├── auth-stack.ts          # Cognito User Pool, App Client
│   │   ├── api-stack.ts           # AppSync API, schema, resolvers
│   │   ├── data-stack.ts          # DynamoDB table, GSIs
│   │   ├── compute-stack.ts       # Lambda functions
│   │   ├── storage-stack.ts       # S3 buckets, CloudFront
│   │   ├── events-stack.ts        # EventBridge rules (migration reminders, recurrence)
│   │   └── monitoring-stack.ts    # CloudWatch dashboards, alarms
│   ├── constructs/
│   │   ├── appsync-api.ts         # Custom AppSync construct
│   │   └── lambda-function.ts     # Standardized Lambda construct with layers
│   └── pipeline-stack.ts          # CDK Pipeline for CI/CD
├── lambda/
│   ├── resolvers/
│   │   ├── board.ts
│   │   ├── task.ts
│   │   ├── marker.ts
│   │   ├── column.ts
│   │   ├── migration.ts
│   │   └── sync.ts
│   ├── events/
│   │   ├── migration-reminder.ts
│   │   └── recurring-task.ts
│   ├── shared/
│   │   ├── dynamo-client.ts
│   │   ├── types.ts               # Shared entity types
│   │   └── auth.ts
│   └── layers/
│       └── common/                # Shared dependencies layer
├── schema/
│   └── schema.graphql             # AppSync schema
├── test/
│   ├── unit/
│   └── integration/
├── cdk.json
├── tsconfig.json
└── package.json
```

---

## 8. Multi-Environment Setup

### 8.1 Environments

| Environment | Purpose | AppSync URL Pattern | Auto-deploy? |
|-------------|---------|---------------------|-------------|
| **dev** | Active development, integration testing | `dev-api.alpha-app.com` | Yes, on every push to `main` |
| **dogfood** | Team members use daily as real users | `dogfood-api.alpha-app.com` | Yes, after dev tests pass |
| **staging** | Pre-production validation, load testing | `staging-api.alpha-app.com` | Manual approval |
| **prod** | End users | `api.alpha-app.com` | Manual approval |

### 8.2 Environment Isolation

Each environment gets its own:
- AWS account (recommended) OR resource name prefix (`alpha-dev-*`, `alpha-dogfood-*`, etc.)
- DynamoDB table
- Cognito User Pool (separate user databases)
- AppSync API endpoint
- S3 buckets
- CloudWatch log groups

### 8.3 Dogfooding Strategy

The **dogfood** environment is a first-class deployment target, not an afterthought:

- **Separate Cognito pool**: Team members create real accounts, not test accounts.
- **Real data**: Team members use it as their actual planner. This surfaces UX friction that test data never reveals.
- **Feature flags**: A `#feature-flag` DynamoDB item per environment controls feature rollout. New features can be enabled in dogfood before staging/prod.
- **Client configuration**: The mobile/web app reads a config endpoint at startup that returns the API URL based on build variant (`debug` -> dev, `dogfood` -> dogfood, `release` -> prod). Developers install a separate "AlPHA Dogfood" app build on their devices.
- **Same infrastructure code**: The CDK pipeline deploys identical stacks to all environments, parameterized only by stage name. No environment-specific logic leaks into application code.

### 8.4 Configuration by Stage

```typescript
interface StageConfig {
  dynamoDbBillingMode: 'ON_DEMAND' | 'PROVISIONED';
  dynamoDbReadCapacity?: number;
  dynamoDbWriteCapacity?: number;
  lambdaMemoryMb: number;
  lambdaTimeoutSeconds: number;
  appSyncCacheTtlSeconds: number;
  logRetentionDays: number;
  alarmSnsTopicArn?: string;
}

const configs: Record<string, StageConfig> = {
  dev:     { dynamoDbBillingMode: 'ON_DEMAND', lambdaMemoryMb: 256, lambdaTimeoutSeconds: 10, appSyncCacheTtlSeconds: 0, logRetentionDays: 7 },
  dogfood: { dynamoDbBillingMode: 'ON_DEMAND', lambdaMemoryMb: 256, lambdaTimeoutSeconds: 10, appSyncCacheTtlSeconds: 60, logRetentionDays: 14 },
  staging: { dynamoDbBillingMode: 'ON_DEMAND', lambdaMemoryMb: 512, lambdaTimeoutSeconds: 10, appSyncCacheTtlSeconds: 60, logRetentionDays: 30 },
  prod:    { dynamoDbBillingMode: 'ON_DEMAND', lambdaMemoryMb: 512, lambdaTimeoutSeconds: 10, appSyncCacheTtlSeconds: 300, logRetentionDays: 90 },
};
```

---

## 9. Cost Optimization

### 9.1 DynamoDB: On-Demand vs Provisioned

**Start with On-Demand for all environments.** Rationale:

- Traffic patterns are unknown at launch. On-demand handles spikes without throttling.
- On-demand pricing: $1.25/million write request units, $0.25/million read request units.
- For a user with 5 boards, 200 tasks, and 500 markers, daily active usage generates roughly 50-100 read/write operations. At 1,000 daily active users, that's ~100K operations/day = ~$4/month.
- **Switch to provisioned** only when traffic stabilizes and on-demand costs exceed provisioned costs by 2x+ (typically at sustained high throughput). Use auto-scaling with provisioned mode.

### 9.2 Lambda Cost Controls

- **Memory**: Start at 256MB. The resolvers are lightweight DynamoDB operations; more memory is unnecessary.
- **ARM64**: Use Graviton2 (arm64) architecture for 20% lower cost and better performance.
- **Bundling**: Use esbuild to tree-shake Lambda bundles, reducing cold start time and execution duration.
- **Lambda Layers**: Shared dependencies (AWS SDK v3 DynamoDB client) in a layer, reused across all functions.
- **Provisioned Concurrency**: Not needed initially. Consider only if cold starts degrade UX on the dogfood environment (measure first).

### 9.3 AppSync Pricing

- $4.00 per million query/mutation operations.
- $2.00 per million real-time subscription updates.
- $0.08 per million connection-minutes.
- At 1,000 DAU with moderate usage: estimated $10-30/month.

### 9.4 Overall Cost Estimate (Pre-Scale)

| Service | Monthly Estimate (1K DAU) |
|---------|--------------------------|
| AppSync | $10-30 |
| Lambda | $1-5 |
| DynamoDB | $3-10 |
| Cognito | Free (first 50K MAU) |
| S3 + CloudFront | $1-5 |
| CloudWatch | $5-10 |
| **Total** | **$20-60/month** |

### 9.5 Cost Guardrails

- Set AWS Budgets alerts at $50, $100, $200/month.
- DynamoDB auto-scaling with maximum capacity limits.
- Lambda concurrency limits per function (prevent runaway invocations).
- CloudWatch anomaly detection alarms on DynamoDB consumed capacity.

---

## 10. Phased Delivery

### Phase 1: Foundation (Weeks 1-3)

**Goal**: Authenticated users can create boards and manage tasks through the API.

**Backend deliverables:**
- CDK project scaffolding with pipeline stack
- DynamoDB table with GSIs
- Cognito User Pool with email sign-up
- AppSync API with schema
- Lambda resolvers: `createBoard`, `getBoard`, `listBoards`, `addTask`, `updateTask`, `completeTask`, `cancelTask`
- Deploy to `dev` environment
- Integration tests for all resolvers

**Frontend alignment**: Auth screens, board list view, task list view (no grid yet).

### Phase 2: The Grid (Weeks 4-6)

**Goal**: Full marker grid functionality -- the core Alastair Method interaction.

**Backend deliverables:**
- Lambda resolvers: `addColumn`, `updateColumn`, `removeColumn`, `reorderColumns`
- Lambda resolvers: `setMarker`, `removeMarker`, `cycleMarker`, `shiftContext`
- Lambda resolvers: `reorderTasks`
- Board templates (pre-built Weekly, Monthly, GTD Context templates)
- `dogfood` environment deployed
- Team begins daily dogfooding

**Frontend alignment**: Grid/matrix view, tap-to-cycle markers, drag-to-reorder, column management.

### Phase 3: Migration & Sync (Weeks 7-9)

**Goal**: Period transitions and multi-device sync.

**Backend deliverables:**
- `migrateTasks` mutation with transactional logic
- AppSync subscriptions for real-time board updates
- Offline conflict resolution Lambda
- `syncBoard` delta query
- EventBridge rule: periodic migration reminder (tasks older than period length)
- Recurring task creation via EventBridge scheduled rule

**Frontend alignment**: Migration flow UI, offline queue indicator, multi-device testing.

### Phase 4: Polish & Production (Weeks 10-12)

**Goal**: Production-ready deployment with monitoring and performance tuning.

**Backend deliverables:**
- `staging` environment deployed
- Load testing against staging (simulate 1K concurrent users)
- CloudWatch dashboards: API latency, error rates, DynamoDB throttles, Lambda durations
- CloudWatch alarms: 5xx error rate > 1%, p99 latency > 2s, DynamoDB throttling
- AppSync response caching tuned per query
- `prod` environment deployed
- Runbook documentation for on-call

**Frontend alignment**: Performance optimization, error handling, app store submission preparation.

### Phase 5: Growth Features (Post-Launch)

**Potential additions (not committed):**
- Board sharing (multi-user boards) -- requires authorization model expansion
- Board export to PDF/image (Lambda + Puppeteer or server-side rendering)
- Analytics dashboard (tasks completed per period, migration rates)
- Push notifications via Amazon Pinpoint (migration reminders, deadline alerts)
- Apple Watch / widget support (lightweight API for today's tasks)

---

## Appendix: Key Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| API style | GraphQL (AppSync) | Nested board graph, built-in subscriptions, offline sync |
| Database | DynamoDB single-table | Key-value access patterns, serverless scaling, cost |
| Auth | Cognito | Managed JWT flow, social federation, free tier |
| IaC | CDK (TypeScript) | AWS-native, type-safe, pipeline built-in |
| Compute | Lambda (ARM64, TS) | Short-lived resolvers, no idle cost |
| Real-time | AppSync subscriptions | Native WebSocket management, no infra overhead |
| Conflict resolution | Version-based + field merge | Marker: last-write-wins; Task: field-level merge |
| Environments | 4 (dev/dogfood/staging/prod) | Dogfood catches UX issues before staging |
| DynamoDB billing | On-demand (all stages) | Unknown traffic patterns; switch when stable |
