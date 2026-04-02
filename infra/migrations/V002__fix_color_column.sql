-- V002: Change tags.color from INTEGER to BIGINT.
-- Flutter Color.value can exceed 2^31 (e.g. 4281032350).
ALTER TABLE tags ALTER COLUMN color TYPE BIGINT;
