# Disaster Recovery Runbook

Triage and recovery procedures for cloud database corruption,
buggy-migration fallout, or large-scale sync data loss.

This runbook is written from one real incident (2026-05-03) where
a schema-v12 client migration assumed milliseconds-since-epoch
when Drift actually stores seconds-since-epoch. The corrupted
local data triggered the dedup-cascade in `BoardRepository.
getByWeekStart`, which hard-deleted boards locally and pushed
13 board soft-deletes to the cloud. Cascading client-side merges
re-FK'd tasks across boards. Recovery took ~3 hours. With the
script-paths in this doc it should take ~30 minutes next time.

## Reflexes — first 60 seconds

1. **Stop the bleeding.** Tell the user to **quit every running
   client** AND that you'll force them to re-authenticate. Without
   re-auth, a still-running client can keep pushing corrupted
   data while you're fixing the cloud — chasing your own tail.
2. **Take a panic snapshot** before any destructive op:
   ```
   aws rds create-db-snapshot \
     --db-instance-identifier alpha-dev \
     --db-snapshot-identifier alpha-dev-panic-$(date -u +%Y-%m-%d-%H%M)
   ```
   Cheap, fast, gives you "undo".
3. **Inventory the damage.** Look at CloudWatch push logs for the
   client that started the cascade — `→ skipped:`,
   "DB connection in error state, rolling back", and bursts of
   `deleted=True` are the signatures.
   ```
   aws logs tail /aws/lambda/alpha-sync-push-dev --since 30m \
     --format short | grep -E "deleted=True|skipped|error|in error"
   ```

## Standard recovery via snapshot or PITR

### Step 1 — pick a restore point

```
aws rds describe-db-snapshots --db-instance-identifier alpha-dev \
  --snapshot-type automated --query \
  'DBSnapshots[*].{id:DBSnapshotIdentifier,created:SnapshotCreateTime}' \
  --output table
aws rds describe-db-instances --db-instance-identifier alpha-dev \
  --query 'DBInstances[0].{retention:BackupRetentionPeriod,latest:LatestRestorableTime}'
```

- Daily automated snapshots fire ~12:39 UTC.
- PITR (`restore-db-instance-to-point-in-time`) gives second-level
  granularity within the retention window. **Earlier-restorable-time
  often shows null in `describe` even when PITR works** — try the
  call before assuming it's unavailable.

Pick the latest restore point that's *before* the corruption.
PITR to ~5 min before is usually best — minimizes data loss.

### Step 2 — restore to a temp instance

```
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier alpha-dev \
  --target-db-instance-identifier alpha-dev-pitr \
  --restore-time 2026-05-03T18:55:00Z \
  --db-instance-class db.t4g.micro \
  --no-publicly-accessible \
  --vpc-security-group-ids $(aws rds describe-db-instances \
      --db-instance-identifier alpha-dev \
      --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
      --output text) \
  --db-subnet-group-name $(aws rds describe-db-instances \
      --db-instance-identifier alpha-dev \
      --query 'DBInstances[0].DBSubnetGroup.DBSubnetGroupName' \
      --output text)
```

ETA: 8–15 min for `db.t4g.micro`. Block on:
```
until [ "$(aws rds describe-db-instances \
  --db-instance-identifier alpha-dev-pitr \
  --query 'DBInstances[0].DBInstanceStatus' --output text)" = "available" ]
do sleep 30; done
```

### Step 3 — bastion + apply newer migrations to the temp

The snapshot/PITR is from before whatever schema migrations were
applied since. Apply each later Vxxx file from `infra/migrations/`
to the **temp** before dumping. Otherwise the dump will be missing
columns the live Lambda code expects.

```
cd infra/bastion && terraform apply -auto-approve
SCP each migrations/Vxxx.sql to bastion
ssh bastion "PGPASSWORD=... psql -h alpha-dev-pitr.... -f Vxxx.sql"
```

### Step 4 — dump-and-restore (no Lambda config changes)

The dump+TRUNCATE+restore approach keeps the live `alpha-dev`
endpoint, so Lambda env vars are unchanged. Avoids touching infra.

```bash
# On bastion. PASS = master password from Secrets Manager.
RESTORED=alpha-dev-pitr.<region>.rds.amazonaws.com
LIVE=alpha-dev.<region>.rds.amazonaws.com

# 1. Dump (NO --disable-triggers — RDS doesn't allow superuser).
PGPASSWORD="$PASS" pg_dump -h "$RESTORED" -U alpha_admin -d alpha \
    --data-only \
    --table=users --table=tags --table=boards \
    --table=board_columns --table=tasks --table=markers \
    --table=task_notes --table=task_tags \
    --table=recurring_series --table=series_tags \
    --table=sync_cursors \
    > /tmp/restore_data.sql

# 2. TRUNCATE live tables (CASCADE handles FKs).
PGPASSWORD="$PASS" psql -h "$LIVE" -U alpha_admin -d alpha <<'EOF'
BEGIN;
TRUNCATE TABLE
    series_tags, task_tags, markers, task_notes, tasks,
    board_columns, recurring_series, boards, tags, sync_cursors,
    users
RESTART IDENTITY CASCADE;
COMMIT;
EOF

# 3. Restore. ON_ERROR_STOP catches FK violations early.
PGPASSWORD="$PASS" psql -h "$LIVE" -U alpha_admin -d alpha \
    -v ON_ERROR_STOP=1 -f /tmp/restore_data.sql
```

### Step 5 — invalidate auth (force fresh sign-in)

**This step was missed in the 2026-05-03 incident.** When the user
launched the macOS app post-restore, it auto-synced as the still-
authenticated user, and stale local sync state interfered with
the recovery.

To force re-auth, **revoke the user's Cognito refresh tokens**:

```
aws cognito-idp admin-user-global-sign-out \
  --user-pool-id us-west-2_0XUQCSZTQ \
  --username <cognito-sub-or-email>
```

This invalidates all refresh tokens issued for that user. Their
next access-token refresh will fail → app falls back to the
sign-in screen → user signs in fresh → first sync uses an empty
local cursor and pulls the full restored state.

### Step 6 — wipe local + sign in fresh

Per device:

- **macOS**: `rm` everything in
  `~/Library/Containers/day.planyr.app/Data/Documents/`
  (planyr.db, planyr.db-shm, planyr.db-wal).
- **Android**: Settings → Apps → Planyr → Storage → **Clear data**
  (NOT just Clear cache).
- **iOS**: delete and reinstall the app.

### Step 7 — tear down temp + bastion

```
aws rds delete-db-instance --db-instance-identifier alpha-dev-pitr \
  --skip-final-snapshot --delete-automated-backups
cd infra/bastion && terraform destroy -auto-approve
```

Keep the **panic snapshot from step 0** for several days before
deleting it manually — you might need to revert.

## Cloud-side cleanup patterns

Sometimes the snapshot itself contains the data damage (because
the corruption was already in flight before the last automated
backup). Two SQL patterns we used in the 2026-05-03 incident:

### Pattern A — board consolidation (one canonical per week)

When duplicate weekly boards exist (different uuids for the same
calendar week, often from offline-create races), pick the
canonical = **board with the most live tasks** (ties: oldest
created_at), re-FK every task from duplicates onto canonical,
re-FK every marker by mapping `column_id` → canonical's
`board_columns` of matching `position`, soft-delete duplicates,
normalize canonical's `week_start` to UTC midnight.

Full SQL: see `infra/recovery/dedup_boards.sql` (committed
alongside this doc).

**Critical**: pick canonical by **most tasks**, not oldest. The
2026-05-03 incident's first attempt used "oldest" and ended up
with the empty post-corruption phantom board winning over the
real one with 11 tasks. The "most tasks" tiebreak handles the
common-case where one duplicate is a freshly-created phantom.

### Pattern B — series-instance dedup (one task per series per board)

The recurring-series materializer can create multiple task rows
for the same `(series_id, board_id)` pair if it runs twice (e.g.,
two devices both materializing). For each such pair, keep the
oldest task as canonical, re-FK any markers from the duplicate
task(s) onto the canonical (drop conflicts on `(task_id,
column_id)` UNIQUE), soft-delete duplicates.

Full SQL: see `infra/recovery/dedup_series.sql`.

### After cleanup: bump updated_at to win LWW

```
UPDATE boards SET updated_at = NOW(), synced_at = NOW()
WHERE user_id = '<uid>' AND deleted_at IS NULL;
```

Without this, the client pulls the corrected rows but its LWW
check skips updates whose incoming `updated_at` isn't strictly
greater than local's.

## Gotchas (paid-in-blood from 2026-05-03)

- **Drift stores DateTime as integer SECONDS since epoch** in Drift
  2.x with default `Native­Database`. Migrations must use raw
  values, not `/1000` or `*1000`. (See the v12 migration in
  `lib/shared/database.dart` for the fixed form, and v13 for the
  cleanup of the buggy version.)
- **`getByWeekStart` is destructive when boards have similar
  `week_start` values.** Its "prefer the one with tasks; delete
  the empty duplicate" path runs `_deleteBoardCascade`, which
  hard-deletes locally AND tombstones for cloud push. A bad
  `week_start` on every board (from a bad migration) makes every
  board look like a duplicate.
- **`pg_dump --disable-triggers` requires superuser.** RDS users
  aren't superusers. Drop the flag and rely on `--data-only`
  emitting tables in dependency order.
- **`EarliestRestorableTime` showing null in `describe` doesn't
  mean PITR is disabled.** It often is — try the
  `restore-db-instance-to-point-in-time` call to confirm.
- **Bumping only `synced_at` doesn't make pull updates land on
  clients.** The client applier does LWW on `updated_at`. Always
  bump both during recovery.
- **`board_columns` has no per-row LWW timestamp.** The applier's
  fallback for tables without timestamps is `INSERT OR REPLACE`,
  which always overwrites — so column data is reliable. But the
  pull-side query filters columns by `bc.synced_at > since`, so
  if you reset only the local cursor without bumping `synced_at`
  on cloud columns, columns won't refetch.
- **Force re-authentication during recovery.** A still-authenticated
  client will auto-sync as soon as it has network + the app is
  open. Use Cognito's `admin-user-global-sign-out` to force fresh
  sign-in before the user wipes local DB.

## Bastion cost

t4g.nano, ~$3/month if left running. Always
`terraform destroy` from `infra/bastion/` after recovery — don't
let it sit. The panic snapshot is the rollback path; the bastion
is just a tool.
