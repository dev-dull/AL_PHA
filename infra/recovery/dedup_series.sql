-- Cloud-side recurring-series instance dedup. For every
-- (series_id, board_id) pair with multiple live task rows, keep
-- the oldest as canonical, re-FK any markers from the duplicates
-- onto canonical (drop conflicts on (task_id, column_id) UNIQUE),
-- soft-delete the duplicates.
--
-- Use after `dedup_boards.sql` if recurring tasks (Take meds,
-- Take out trash, etc.) appear multiple times in the UI for the
-- same week. Caused by the materializer running more than once
-- per (series, week) — typically a side effect of a sync mishap
-- where two devices each materialize independently.
--
-- No user_id substitution needed — operates on tasks with
-- non-null series_id, all of which are necessarily owned via
-- their parent series row.

BEGIN;

CREATE TEMP TABLE series_canonical AS
SELECT DISTINCT ON (series_id, board_id)
  id AS canonical_id, series_id, board_id, created_at
FROM tasks
WHERE deleted_at IS NULL
  AND series_id IS NOT NULL
ORDER BY series_id, board_id, created_at, id;

CREATE TEMP TABLE series_dup AS
SELECT t.id AS dup_id, sc.canonical_id, t.board_id, t.title
FROM tasks t
JOIN series_canonical sc
  ON sc.series_id = t.series_id
 AND sc.board_id = t.board_id
WHERE t.deleted_at IS NULL
  AND t.id != sc.canonical_id;

-- Drop canonical-side markers that would collide on
-- (task_id, column_id) UNIQUE after re-FK.
WITH dup_markers AS (
  SELECT m.id AS dup_marker_id, sd.canonical_id AS new_task_id, m.column_id
  FROM markers m
  JOIN series_dup sd ON sd.dup_id = m.task_id
  WHERE m.deleted_at IS NULL
)
DELETE FROM markers m
USING dup_markers dm,
      markers m_canon
WHERE m.id = dm.dup_marker_id
  AND m_canon.task_id = dm.new_task_id
  AND m_canon.column_id = dm.column_id
  AND m_canon.deleted_at IS NULL;

-- Re-FK surviving dup markers onto canonical.
UPDATE markers m
SET task_id = sd.canonical_id,
    updated_at = NOW(),
    synced_at = NOW()
FROM series_dup sd
WHERE m.task_id = sd.dup_id
  AND m.deleted_at IS NULL;

-- Soft-delete the duplicate task rows.
UPDATE tasks
SET deleted_at = NOW(), synced_at = NOW()
WHERE id IN (SELECT dup_id FROM series_dup);

-- Verification: each (series_id, board_id) should now have
-- exactly one live row.
SELECT series_id::text, board_id::text, COUNT(*) AS live_count
FROM tasks
WHERE deleted_at IS NULL AND series_id IS NOT NULL
GROUP BY series_id, board_id
HAVING COUNT(*) > 1;

COMMIT;
