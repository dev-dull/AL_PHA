-- Cloud-side board consolidation: one canonical board per
-- calendar week, all weekStarts normalized to UTC midnight.
--
-- Use when sync mishaps (offline-create races, buggy migrations,
-- bad dedup runs) leave the cloud with multiple weekly boards
-- whose week_starts only differ by hours (typically Pacific
-- midnight = 07:00 UTC vs UTC midnight = 00:00 UTC).
--
-- Canonical = the live board with the MOST live tasks for the
-- calendar week (ties: oldest created_at). Picking by tasks
-- avoids losing the user's primary board to a freshly-created
-- empty phantom (a real failure mode we've seen).
--
-- Required substitution: `<USER_ID>` — the Cognito sub of the
-- affected user.
--
-- Run inside `BEGIN; ... COMMIT;` if you want to inspect first.

BEGIN;

CREATE TEMP TABLE board_canonical AS
WITH ranked AS (
  SELECT
    b.id,
    date_trunc('day', b.week_start AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' AS week_utc,
    b.created_at,
    (SELECT COUNT(*) FROM tasks t
       WHERE t.board_id = b.id AND t.deleted_at IS NULL) AS live_tasks
  FROM boards b
  WHERE b.user_id = '<USER_ID>'
    AND b.deleted_at IS NULL
    AND b.type = 'weekly'
    AND b.week_start IS NOT NULL
)
SELECT DISTINCT ON (week_utc)
  week_utc, id AS canonical_id
FROM ranked
ORDER BY week_utc, live_tasks DESC, created_at ASC, id ASC;

CREATE TEMP TABLE board_dup AS
SELECT
  b.id AS dup_id,
  bc.canonical_id,
  bc.week_utc
FROM boards b
JOIN board_canonical bc
  ON date_trunc('day', b.week_start AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' = bc.week_utc
WHERE b.user_id = '<USER_ID>'
  AND b.deleted_at IS NULL
  AND b.type = 'weekly'
  AND b.id != bc.canonical_id;

-- Re-FK tasks from duplicate boards onto canonical.
UPDATE tasks t
SET board_id = bd.canonical_id,
    updated_at = NOW(),
    synced_at = NOW()
FROM board_dup bd
WHERE t.board_id = bd.dup_id
  AND t.deleted_at IS NULL;

-- Re-FK markers via column position. Drop canonical-side conflicts
-- on (task_id, column_id) — duplicate's wins (it's the more
-- recent state in the post-corruption aftermath).
WITH dup_markers AS (
  SELECT m.id AS dup_marker_id, m.task_id,
         bc_canonical.id AS new_column_id,
         bd.canonical_id AS new_board_id
  FROM markers m
  JOIN board_dup bd ON bd.dup_id = m.board_id
  JOIN board_columns bc_dup ON bc_dup.id = m.column_id
  JOIN board_columns bc_canonical
    ON bc_canonical.board_id = bd.canonical_id
   AND bc_canonical.position = bc_dup.position
  WHERE m.deleted_at IS NULL
),
collisions AS (
  DELETE FROM markers m_canon
  USING dup_markers dm
  WHERE m_canon.task_id = dm.task_id
    AND m_canon.column_id = dm.new_column_id
    AND m_canon.id != dm.dup_marker_id
  RETURNING m_canon.id
)
UPDATE markers m
SET board_id = dm.new_board_id,
    column_id = dm.new_column_id,
    updated_at = NOW(),
    synced_at = NOW()
FROM dup_markers dm
WHERE m.id = dm.dup_marker_id;

-- Soft-delete duplicates.
UPDATE boards
SET deleted_at = NOW(), synced_at = NOW()
WHERE id IN (SELECT dup_id FROM board_dup);

-- Normalize canonical's week_start to UTC midnight + bump
-- updated_at so client LWW accepts.
UPDATE boards b
SET week_start = bc.week_utc,
    updated_at = NOW(),
    synced_at = NOW()
FROM board_canonical bc
WHERE b.id = bc.canonical_id;

-- Verification.
SELECT b.id::text, b.name, b.week_start,
       (SELECT COUNT(*) FROM tasks t
          WHERE t.board_id = b.id AND t.deleted_at IS NULL) AS live_tasks
FROM boards b
WHERE b.user_id = '<USER_ID>'
  AND b.deleted_at IS NULL
  AND b.type = 'weekly'
ORDER BY b.week_start DESC;

COMMIT;
