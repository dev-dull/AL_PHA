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

Uses native SRP auth via `amazon_cognito_identity_dart_2` with in-app sign-in/sign-up/verification dialogs (no browser redirect).

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
- Runtime: python3.12
- Memory: 256MB
- Timeout: 30s
- VPC: yes (same VPC as RDS)
- Environment: DB connection string from Secrets Manager
- Dependencies: psycopg2-binary (Postgres), packaged as Lambda layer or zip
```

**Decided:** Python 3.12 for Lambda (developer's primary backend language). psycopg2 packaged as Lambda layer.

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

Use **Flyway** for versioned SQL migrations. Each migration is a numbered SQL file checked into the repo:

```
infra/migrations/
├── V001__initial_schema.sql
├── V002__add_task_notes.sql
├── V003__add_tags.sql
└── ...
```

Flyway runs as `docker run flyway/flyway migrate` in CI (GitHub Actions) on merge to main. It tracks applied migrations in a `flyway_schema_history` table and provides validation and repair commands for production issues. Migrations run before deploying new Lambda code — never from the app itself.

### Initial Schema (V001)

Maps to the Drift/SQLite schema (now at v9), plus sync metadata:

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

### Lambda Directory Structure (Implemented)

```
lambda/
├── requirements.txt       # psycopg2-binary
├── sync_push.py           # POST /sync/push — upsert with LWW, FK dependency ordering, orphan skipping
├── sync_pull.py           # POST /sync/pull — changes since cursor in FK dependency order
├── sync_status.py         # GET /sync/status — device list and per-table row counts
├── migrate_upload.py      # POST /migrate/upload — S3 blob storage with transfer codes
├── migrate_download.py    # POST /migrate/download/{code} — one-time retrieval + S3 deletion
└── shared/
    ├── db.py              # Connection pooling (psycopg2), transaction management
    ├── auth.py            # JWT extraction, auto-user creation with autocommit
    └── response.py        # JSON serialization with epoch-second timestamps
```

### Schema Versioning Strategy

When a new app version adds columns or tables:

1. Add a Flyway migration to Postgres (e.g., `V004__add_new_field.sql`)
2. Run Flyway migration in CI before deploying new Lambda code
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

### New Packages (Implemented)
- `amazon_cognito_identity_dart_2` for native SRP Cognito auth (no browser redirect)
- `http` for sync/migration API calls
- `shared_preferences` for token persistence

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

### Local Schema Changes (Drift v9 — Implemented)

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

To know what to push, scan all tables for rows where `updatedAt > lastSyncTime`. Data is <10MB so the full scan takes milliseconds. A changelog table can be added later if performance requires it.

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
          docker run --rm \
            -v ${{ github.workspace }}/infra/migrations:/flyway/sql \
            flyway/flyway \
            -url="$FLYWAY_URL" \
            -user="$FLYWAY_USER" \
            -password="$FLYWAY_PASSWORD" \
            migrate
        env:
          FLYWAY_URL: ${{ secrets.FLYWAY_URL }}
          FLYWAY_USER: ${{ secrets.FLYWAY_USER }}
          FLYWAY_PASSWORD: ${{ secrets.FLYWAY_PASSWORD }}
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
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: |
          cd lambda
          pip install -r requirements.txt -t package/
          cd package && zip -r ../function.zip .
          cd .. && zip function.zip *.py
      - run: |
          aws lambda update-function-code \
            --function-name alpha-sync-push \
            --zip-file fileb://lambda/function.zip
      # Repeat for each function, or use a matrix
```

---

## Implementation Order

### Phase 1: Infrastructure (Terraform) -- DONE
1. ~~Set up Terraform backend (S3 state bucket + DynamoDB lock table)~~ -- bootstrap.sh
2. ~~Deploy Cognito user pool~~ -- cognito.tf
3. ~~Deploy RDS Postgres~~ -- rds.tf (db.t4g.micro, Postgres 16, private subnet)
4. ~~Run initial schema migration (V001)~~ -- V001 + V002 via bastion
5. ~~Deploy API Gateway + Lambda stubs~~ -- api_gateway.tf, lambda.tf (5 functions)
6. ~~Deploy S3 migration bucket~~ -- s3.tf (24h lifecycle)
Also deployed: VPC, IAM roles, Secrets Manager VPC endpoint, psycopg2 Lambda layer, bastion module (infra/bastion/), teardown.sh

### Phase 2: One-Time Migration -- PARTIALLY DONE
7. ~~Implement Lambda: migrate/upload, migrate/download~~ -- DONE (S3 blob + transfer codes, one-time retrieval)
8. Implement Flutter: migration_screen.dart, migration_repository.dart -- NOT YET (see #35)
9. Add "Transfer Data" to Settings screen -- NOT YET
10. Test: export on one device, import on another -- NOT YET

### Phase 3: Auth -- DONE
11. ~~Implement Flutter auth flow (sign up, sign in, sign out)~~ -- native SRP via amazon_cognito_identity_dart_2 (no browser redirect)
12. ~~Add auth state to Settings screen~~ -- Account section with sync status
13. Gate sync features behind auth + plan_tier -- auth gating done, plan_tier gating deferred to #33

### Phase 4: Sync -- DONE
14. ~~Implement Lambda: sync/push, sync/pull~~ -- LWW upsert, FK dependency ordering, orphan row skipping
15. ~~Implement Flutter: sync_repository.dart, change tracking~~ -- 12 change tracker smoke tests
16. ~~Add sync trigger points (app open, after write, periodic)~~ -- app start (3s), data changes (5s debounce), Sync Now button
17. ~~Add sync indicator to app bar~~ -- cloud icon (green=syncing, faded green=synced, red=error)
18. Test: modify on device A, see changes on device B -- manual testing in progress

### Phase 5: Payments -- NOT STARTED
19. RevenueCat or Stripe for subscription management -- see #33
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

## Decisions

1. **Lambda runtime:** Python 3.12 (developer's primary backend language). psycopg2 packaged as Lambda layer.
2. **Migration tool:** Flyway. Heavier than golang-migrate but validation/repair features are worth it for planned, infrequent migrations. Runs as Docker container in CI.
3. **Cognito UI:** Changed from hosted sign-in to native SRP via `amazon_cognito_identity_dart_2` for better UX (no browser redirect). In-app dialogs for sign-in, sign-up, and email verification.
4. **Change tracking:** Timestamp scan (compare `updatedAt > lastSyncTime`). Simpler implementation; data is <10MB so full scan is milliseconds. Changelog table can be added later if needed.
5. **Team planners:** Skip `board_members` table for now. Add as a future Flyway migration when the feature is designed.
6. **Timestamp serialization:** Lambda returns epoch seconds (not ISO strings). All Flutter storage uses UTC; display converts to local timezone.
7. **SQL injection prevention:** All dynamic table/column names use `psycopg2.sql.Identifier` — no string interpolation in SQL.
8. **Sync pull handling:** Client strips server-only columns, converts epoch-second timestamps, and deduplicates boards by week_start.
