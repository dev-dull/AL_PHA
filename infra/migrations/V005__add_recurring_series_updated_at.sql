-- V005: recurring_series needs updated_at for proper LWW + the
-- series_tags scan. Mirrors V004 (which gave tags an updated_at).
--
-- Pre-fix, the client's change-tracker scanned series_tags via
-- `JOIN recurring_series WHERE rs.created_at > ?` and the lambda
-- compared incoming series rows against `created_at` for LWW.
-- Both used a column that never moves after row creation, so any
-- post-creation edit (rename, recurrence-rule change, tag-set
-- edit) silently never reached the cloud (#52).
--
-- The corresponding client-side fix (Drift schema v14) bumps
-- recurring_series.updated_at on every mutation. The push handler
-- is updated to use that column for LWW.

ALTER TABLE recurring_series ADD COLUMN updated_at TIMESTAMPTZ;

-- Backfill: existing series get updated_at = created_at so the
-- LWW comparison stays sensible until the next client-side edit
-- moves it. Without backfill, an edit from one client would
-- always lose to a NULL stored timestamp.
UPDATE recurring_series
SET updated_at = created_at
WHERE updated_at IS NULL;

ALTER TABLE recurring_series ALTER COLUMN updated_at SET NOT NULL;
