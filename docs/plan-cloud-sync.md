# Cloud Sync & Multi-Device Architecture Plan

## Overview

Add multi-device sync and one-time migration to AlPHA using AWS infrastructure. Local Drift/SQLite remains the source of truth on each device. A Postgres database in RDS serves as the cloud source of truth. Sync is bidirectional with per-field last-write-wins conflict resolution.

## AWS Infrastructure (Terraform)

All infrastructure is defined in `infra/` using Terraform. Target: account 773469078444, us-west-2.

### Resources

```
infra/
├── main.tf              # Provider, backend config
├── variables.tf         # Environment, region, etc.
├── cognito.tf           # User pool, app client
├── rds.tf               # Postgres instance
├── api_gateway.tf       # HTTP API
├── lambda.tf            # Sync functions
├── s3.tf                # Migration transfer bucket
├── iam.tf               # Lambda execution roles
├── outputs.tf           # API URL, Cognito pool ID, etc.
└── terraform.tfvars     # Non-secret config values
```

### Cognito (Auth)

```hcl
# cognito.tf
- User pool with email sign-up/sign-in
- No MFA for MVP (add later)
- App client with SRP auth flow (no client secret — mobile app)
- Custom attributes: plan_tier (free | sync | migrating)
```

**Preference question:** Do you want Cognito-hosted UI for sign-in, or fully custom Flutter UI with Cognito API calls? Hosted UI is faster to ship but less control over appearance.

### RDS Postgres

```hcl
# rds.tf
- db.t4g.micro (free tier eligible, 2 vCPU, 1GB RAM)
- Postgres 16
- 20GB gp3 storage, auto-scaling to 100GB
- Private subnet (Lambda access only, no public endpoint)
- Automated backups, 7-day retention
- Multi-AZ: off for MVP, on for production
```

Schema migrations are NOT managed by Terraform. See "Schema Migrations" section below.

### API Gateway

```hcl
# api_gateway.tf
- HTTP API (v2, cheaper than REST)
- Cognito JWT authorizer
- Routes:
    POST   /sync/push      → lambda_sync_push
    POST   /sync/pull      → lambda_sync_pull
    POST   /migrate/upload  → lambda_migrate_upload
    POST   /migrate/download/{code} → lambda_migrate_download
    GET    /sync/status     → lambda_sync_status
```

### Lambda Functions

```hcl
# lambda.tf
- Runtime: provided.al2023 (Dart compiled to native via dart compile exe)
  OR nodejs22.x if Dart Lambda support is too painful
- Memory: 256MB
- Timeout: 30s
- VPC: yes (same VPC as RDS)
- Environment: DB connection string from Secrets Manager
```

**Preference question:** Dart or Node.js for Lambda? Dart keeps the codebase single-language but Lambda tooling is less mature. Node.js has first-class Lambda support and the pg library is battle-tested.

### S3 (Migration Transfers)

```hcl
# s3.tf
- Bucket: alpha-migrations-{account_id}
- Lifecycle rule: delete objects after 24 hours
- Server-side encryption: AES-256
- No public access
```

### Secrets Manager

```hcl
# In rds.tf or separate secrets.tf
- RDS master password (auto-generated, rotated)
- Referenced by Lambda via environment variable
```

---

## Database Schema (Postgres)

### Migration Tool

Use **Flyway** or **golang-migrate** for versioned SQL migrations. Each migration is a numbered SQL file checked into the repo:

```
infra/migrations/
├── V001__initial_schema.sql
├── V002__add_task_notes.sql
├── V003__add_tags.sql
└── ...
```

**Preference question:** Flyway (Java-based, mature, has Docker image) or golang-migrate (single binary, simpler)? Both support Postgres and can run in CI or as a Lambda/ECS task.

Migrations run as a CI step or a dedicated Lambda triggered on deploy — never from the app itself.

### Initial Schema (V001)

Maps 1:1 to the Drift/SQLite schema v7, plus sync metadata:

```sql
-- Users (Cognito is authoritative, this caches profile data)
CREATE TABLE users (
    id          TEXT PRIMARY KEY,  -- Cognito sub
    email       TEXT NOT NULL,
    plan_tier   TEXT NOT NULL DEFAULT 'free',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Boards
CREATE TABLE boards (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id),
    name        TEXT NOT NULL,
    type        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL,
    archived    BOOLEAN NOT NULL DEFAULT false,
    week_start  TIMESTAMPTZ,
    deleted_at  TIMESTAMPTZ  -- soft delete for sync
);
CREATE INDEX idx_boards_user ON boards(user_id);

-- Board columns
CREATE TABLE board_columns (
    id          TEXT PRIMARY KEY,
    board_id    TEXT NOT NULL REFERENCES boards(id),
    label       TEXT NOT NULL,
    position    INTEGER NOT NULL,
    type        TEXT NOT NULL DEFAULT 'custom',
    deleted_at  TIMESTAMPTZ
);

-- Tasks
CREATE TABLE tasks (
    id                      TEXT PRIMARY KEY,
    board_id                TEXT NOT NULL REFERENCES boards(id),
    user_id                 TEXT NOT NULL REFERENCES users(id),
    title                   TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    state                   TEXT NOT NULL DEFAULT 'open',
    priority                INTEGER NOT NULL DEFAULT 0,
    position                INTEGER NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at            TIMESTAMPTZ,
    deadline                TIMESTAMPTZ,
    migrated_from_board_id  TEXT,
    migrated_from_task_id   TEXT,
    is_event                BOOLEAN NOT NULL DEFAULT false,
    scheduled_time          TEXT,
    recurrence_rule         TEXT,
    deleted_at              TIMESTAMPTZ
);
CREATE INDEX idx_tasks_board ON tasks(board_id);
CREATE INDEX idx_tasks_user ON tasks(user_id);

-- Markers
CREATE TABLE markers (
    id          TEXT PRIMARY KEY,
    task_id     TEXT NOT NULL REFERENCES tasks(id),
    column_id   TEXT NOT NULL REFERENCES board_columns(id),
    board_id    TEXT NOT NULL REFERENCES boards(id),
    symbol      TEXT NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL,
    deleted_at  TIMESTAMPTZ,
    UNIQUE(task_id, column_id)
);

-- Task notes
CREATE TABLE task_notes (
    id          TEXT PRIMARY KEY,
    task_id     TEXT NOT NULL REFERENCES tasks(id),
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL,
    deleted_at  TIMESTAMPTZ
);

-- Tags (per-user)
CREATE TABLE tags (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id),
    name        TEXT NOT NULL,
    color       INTEGER NOT NULL,
    position    INTEGER NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    deleted_at  TIMESTAMPTZ
);
CREATE INDEX idx_tags_user ON tags(user_id);

-- Task-tag assignments
CREATE TABLE task_tags (
    task_id     TEXT NOT NULL REFERENCES tasks(id),
    tag_id      TEXT NOT NULL REFERENCES tags(id),
    slot        INTEGER NOT NULL,
    deleted_at  TIMESTAMPTZ,
    PRIMARY KEY (task_id, tag_id)
);

-- Sync tracking (per device)
CREATE TABLE sync_cursors (
    user_id     TEXT NOT NULL REFERENCES users(id),
    device_id   TEXT NOT NULL,
    last_synced TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, device_id)
);
```

Key differences from SQLite schema:
- `user_id` on boards, tasks, tags (multi-tenant)
- `deleted_at` on all data tables (soft delete for sync — devices need to know something was deleted)
- `updated_at` on tasks (already exists on markers/notes, added to tasks for conflict resolution)
- `sync_cursors` tracks each device's last sync point

### Schema Versioning Strategy

When a new app version adds columns or tables:

1. Add a Flyway/migrate migration to Postgres (e.g., `V004__add_new_field.sql`)
2. Run migration in CI before deploying new Lambda code
3. Bump Drift schema version in the app (e.g., v7 → v8)
4. The app's Drift migration handles the local SQLite change
5. The sync protocol handles the new field — old devices ignore unknown columns, new devices send them

The sync protocol must be forwards-compatible:
- Server accepts and stores unknown fields (JSONB overflow column if needed)
- Old clients skip fields they don't recognize
- This avoids forced app updates for minor schema changes

---

## Sync Protocol

### Push (Device → Server)

```
POST /sync/push
Authorization: Bearer {cognito_jwt}

{
  "device_id": "uuid",
  "changes": [
    {
      "table": "tasks",
      "id": "uuid",
      "data": { ... full row ... },
      "updated_at": "2026-03-28T10:00:00Z",
      "deleted": false
    },
    ...
  ]
}
```

Server logic for each change:
1. Look up the row by `(table, id)`
2. If not found → INSERT
3. If found and `incoming.updated_at > server.updated_at` → UPDATE
4. If found and `incoming.updated_at <= server.updated_at` → SKIP (server wins tie)
5. If `deleted: true` → SET `deleted_at = updated_at` (soft delete)

Response:
```json
{
  "accepted": 142,
  "rejected": 3,
  "server_time": "2026-03-28T10:00:01Z"
}
```

### Pull (Server → Device)

```
POST /sync/pull
Authorization: Bearer {cognito_jwt}

{
  "device_id": "uuid",
  "since": "2026-03-27T00:00:00Z"
}
```

Server logic:
1. Query all rows where `updated_at > since` OR `deleted_at > since` for this user
2. Return them in dependency order: tags → boards → board_columns → tasks → markers, task_notes, task_tags
3. Update `sync_cursors` for this device

Response:
```json
{
  "changes": [ ... rows ... ],
  "server_time": "2026-03-28T10:00:01Z"
}
```

Device logic:
1. For each row: UPSERT into local SQLite
2. For deleted rows (`deleted_at` set): DELETE from local SQLite
3. Store `server_time` as the next `since` value

### Sync Trigger Points

- App open (foreground)
- After any local write (debounced, 5-second delay)
- Periodic background sync (platform-dependent, 15-minute minimum on Android)
- Manual "Sync Now" button in Settings

### Conflict Resolution

Per-field last-write-wins using `updated_at`. The data model is naturally granular:
- Marking a task done = marker row change
- Adding a note = new task_note row
- Changing a tag = task_tag row change

These rarely collide. If two devices edit the same row's same field, the later timestamp wins silently. No user-facing merge UI for MVP.

---

## One-Time Migration (No Account Required)

For users who pay for a device transfer but don't want ongoing sync.

### Upload (Old Device)

```
POST /migrate/upload
Authorization: none (or a temporary anonymous token)

Body: encrypted JSON blob (all tables)
```

Server logic:
1. Generate a 6-digit alphanumeric code
2. Store the blob in S3 with key `migrations/{code}.json.enc`
3. Set 24-hour TTL
4. Return the code

### Download (New Device)

```
POST /migrate/download/{code}

Body: { "code": "ABC123" }
```

Server logic:
1. Look up `migrations/{code}.json.enc` in S3
2. Return the blob
3. Delete the S3 object (one-time use)

Device logic:
1. Decrypt the blob
2. Import all rows into local SQLite (same as sync pull, but full dataset)

### Encryption

- App generates a random AES-256 key
- Encrypts the JSON blob client-side
- Displays the key as part of the transfer code (e.g., code = `ABC123-XXXX` where XXXX derives the key)
- Server never sees plaintext data

---

## Flutter Client Changes

### New Packages
- `amazon_cognito_identity_dart_2` or `amplify_auth_cognito` for Cognito auth
- `http` or `dio` for API calls (already may have one)

### New Feature Directory

```
lib/features/sync/
├── data/
│   ├── sync_repository.dart       # Push/pull API calls
│   └── migration_repository.dart  # Upload/download migration
├── domain/
│   ├── sync_state.dart            # Syncing, synced, error, offline
│   └── sync_change.dart           # Represents a row change
├── providers/
│   └── sync_providers.dart        # Sync state, trigger sync
└── presentation/
    ├── sync_indicator.dart        # Status icon in app bar
    └── migration_screen.dart      # Transfer flow UI
```

### Local Schema Changes (Drift v8)

```dart
// Add to all data tables:
DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

// New table:
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
// Stores: device_id, last_sync_time, user_id, auth_tokens
```

### Change Tracking

To know what to push, track local changes since last sync:

**Option A: Changelog table** — trigger-like: every write appends to a `local_changes` table with `(table, row_id, timestamp)`. Push reads this table, then clears it after successful push.

**Option B: Compare `updatedAt` against `lastSyncTime`** — scan all tables for rows where `updatedAt > lastSyncTime`. Simpler but requires a full scan.

Option A is more efficient for ongoing sync. Option B is simpler and fine given the small data size.

**Preference question:** Changelog table (more code, efficient) or timestamp scan (less code, full scan each sync)? Given your data is <10MB, the scan takes milliseconds either way.

---

## CI/CD Pipeline

### Infrastructure Deploys

```yaml
# .github/workflows/infra.yml
on:
  push:
    paths: ['infra/**']
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan -out=plan.tfplan
      - run: terraform apply plan.tfplan
        # Only on main, after plan review
```

### Database Migrations

```yaml
# .github/workflows/migrate.yml
on:
  push:
    paths: ['infra/migrations/**']
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          # Run Flyway/golang-migrate against RDS
          # Connection string from GitHub Secrets
          migrate -path infra/migrations -database "$DB_URL" up
```

### Lambda Deploys

```yaml
# .github/workflows/lambda.yml
on:
  push:
    paths: ['lambda/**']
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd lambda && npm ci && npm run build
      - run: |
          zip -j function.zip lambda/dist/*
          aws lambda update-function-code \
            --function-name alpha-sync-push \
            --zip-file fileb://function.zip
      # Repeat for each function, or use a matrix
```

---

## Implementation Order

### Phase 1: Infrastructure (Terraform)
1. Set up Terraform backend (S3 state bucket + DynamoDB lock table)
2. Deploy Cognito user pool
3. Deploy RDS Postgres
4. Run initial schema migration (V001)
5. Deploy API Gateway + Lambda stubs
6. Deploy S3 migration bucket

### Phase 2: One-Time Migration
7. Implement Lambda: migrate/upload, migrate/download
8. Implement Flutter: migration_screen.dart, migration_repository.dart
9. Add "Transfer Data" to Settings screen
10. Test: export on one device, import on another

### Phase 3: Auth
11. Implement Flutter auth flow (sign up, sign in, sign out)
12. Add auth state to Settings screen
13. Gate sync features behind auth + plan_tier

### Phase 4: Sync
14. Implement Lambda: sync/push, sync/pull
15. Implement Flutter: sync_repository.dart, change tracking
16. Add sync trigger points (app open, after write, periodic)
17. Add sync indicator to app bar
18. Test: modify on device A, see changes on device B

### Phase 5: Payments
19. RevenueCat or Stripe for subscription management
20. Gate sync behind paid plan
21. Gate migration behind one-time purchase

---

## Cost Estimate (Monthly)

| Resource | Free Tier | After Free Tier |
|----------|-----------|-----------------|
| Cognito | 50k MAU free | $0.0055/MAU after |
| RDS db.t4g.micro | 12 months free | ~$15/month |
| API Gateway | 1M requests free | $1/million after |
| Lambda | 1M requests free | $0.20/million after |
| S3 (migrations) | 5GB free | Pennies |
| Data transfer | 100GB free | $0.09/GB after |
| **Total (< 1000 users)** | **$0** | **~$20/month** |

---

## Open Questions

1. **Lambda runtime:** Dart (single language) or Node.js (better Lambda tooling)?
2. **Migration tool:** Flyway or golang-migrate?
3. **Cognito UI:** Hosted sign-in or custom Flutter UI?
4. **Change tracking:** Changelog table or timestamp scan?
5. **Team planners:** Do we need to plan the `board_members` table now, or add it as a future migration?
