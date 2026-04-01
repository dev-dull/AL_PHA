-- V001: Initial schema — mirrors Drift/SQLite v8 + sync metadata.

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
    deleted_at  TIMESTAMPTZ
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
CREATE INDEX idx_board_columns_board ON board_columns(board_id);

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
    series_id               TEXT,
    deleted_at              TIMESTAMPTZ
);
CREATE INDEX idx_tasks_board ON tasks(board_id);
CREATE INDEX idx_tasks_user ON tasks(user_id);
CREATE INDEX idx_tasks_series ON tasks(series_id);

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
CREATE INDEX idx_markers_board ON markers(board_id);

-- Task notes
CREATE TABLE task_notes (
    id          TEXT PRIMARY KEY,
    task_id     TEXT NOT NULL REFERENCES tasks(id),
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL,
    deleted_at  TIMESTAMPTZ
);
CREATE INDEX idx_task_notes_task ON task_notes(task_id);

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

-- Recurring series
CREATE TABLE recurring_series (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id),
    title           TEXT NOT NULL,
    description     TEXT NOT NULL DEFAULT '',
    priority        INTEGER NOT NULL DEFAULT 0,
    recurrence_rule TEXT NOT NULL,
    is_event        BOOLEAN NOT NULL DEFAULT false,
    scheduled_time  TEXT,
    created_at      TIMESTAMPTZ NOT NULL,
    ended_at        TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ
);
CREATE INDEX idx_recurring_series_user ON recurring_series(user_id);

-- Series tag assignments
CREATE TABLE series_tags (
    series_id   TEXT NOT NULL REFERENCES recurring_series(id),
    tag_id      TEXT NOT NULL REFERENCES tags(id),
    slot        INTEGER NOT NULL,
    deleted_at  TIMESTAMPTZ,
    PRIMARY KEY (series_id, tag_id)
);

-- Sync tracking (per device)
CREATE TABLE sync_cursors (
    user_id     TEXT NOT NULL REFERENCES users(id),
    device_id   TEXT NOT NULL,
    last_synced TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, device_id)
);
