-- V004: tags need updated_at for proper LWW conflict resolution.
--
-- Previously, push compared incoming tag rows against the local
-- created_at, which never moves after insert. Two devices both
-- "winning" with their respective edits would race based on push
-- order, not user-intent ordering — and in the bug we hit, a tag
-- recolor on macOS never overwrote the older red row in the cloud
-- because the timestamp comparison was a no-op.
--
-- The corresponding client-side fix (Drift schema v11) bumps
-- tags.updated_at on every mutation. The push handler is updated
-- to use that column for LWW.
--
-- Pull side already used the server-stamped synced_at (V003) so
-- no change is needed there for change-detection — only LWW.

ALTER TABLE tags ADD COLUMN updated_at TIMESTAMPTZ;

-- Backfill: existing tags get updated_at = created_at so the LWW
-- comparison stays sensible until the next client-side edit moves
-- it. Without backfill, an edit from one client would always lose
-- to a NULL stored timestamp.
UPDATE tags SET updated_at = created_at WHERE updated_at IS NULL;

ALTER TABLE tags ALTER COLUMN updated_at SET NOT NULL;
