"""POST /sync/pull — return changes since a given timestamp."""

import json
import logging
from datetime import datetime, timezone

from shared.auth import ensure_user
from shared.db import commit, execute, rollback
from shared.response import error, server_time, success

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Tables returned in dependency order so the client can insert
# without hitting FK violations.
#
# Every query filters on the row's server-stamped `synced_at` (V003).
# That column is set to NOW() on every insert / update / soft-delete
# in sync_push, so the cursor-vs-row comparison stays in server time
# and is immune to client clock skew or push lag. Each query takes
# exactly two parameters: (user_id, since).
PULL_TABLES = [
    {
        "name": "tags",
        "query": """
            SELECT id, name, color, position, created_at, updated_at,
                   deleted_at
            FROM tags
            WHERE user_id = %s AND synced_at > %s
        """,
    },
    {
        "name": "boards",
        "query": """
            SELECT id, name, type, created_at, updated_at,
                   archived, week_start, deleted_at
            FROM boards
            WHERE user_id = %s AND synced_at > %s
        """,
    },
    {
        "name": "board_columns",
        "query": """
            SELECT bc.id, bc.board_id, bc.label, bc.position,
                   bc.type, bc.deleted_at
            FROM board_columns bc
            JOIN boards b ON bc.board_id = b.id
            WHERE b.user_id = %s AND bc.synced_at > %s
        """,
    },
    {
        "name": "recurring_series",
        "query": """
            SELECT id, title, description, priority, recurrence_rule,
                   is_event, scheduled_time, created_at, updated_at,
                   ended_at, deleted_at
            FROM recurring_series
            WHERE user_id = %s AND synced_at > %s
        """,
    },
    {
        "name": "tasks",
        "query": """
            SELECT id, board_id, title, description, state, priority,
                   position, created_at, updated_at, completed_at,
                   deadline, migrated_from_board_id,
                   migrated_from_task_id, is_event, scheduled_time,
                   recurrence_rule, series_id, deleted_at
            FROM tasks
            WHERE user_id = %s AND synced_at > %s
        """,
    },
    {
        "name": "markers",
        "query": """
            SELECT m.id, m.task_id, m.column_id, m.board_id,
                   m.symbol, m.updated_at, m.deleted_at
            FROM markers m
            JOIN boards b ON m.board_id = b.id
            WHERE b.user_id = %s AND m.synced_at > %s
        """,
    },
    {
        "name": "task_notes",
        "query": """
            SELECT tn.id, tn.task_id, tn.content,
                   tn.created_at, tn.updated_at, tn.deleted_at
            FROM task_notes tn
            JOIN tasks t ON tn.task_id = t.id
            WHERE t.user_id = %s AND tn.synced_at > %s
        """,
    },
    {
        "name": "task_tags",
        "query": """
            SELECT tt.task_id, tt.tag_id, tt.slot, tt.deleted_at
            FROM task_tags tt
            JOIN tasks t ON tt.task_id = t.id
            WHERE t.user_id = %s AND tt.synced_at > %s
        """,
    },
    {
        "name": "series_tags",
        "query": """
            SELECT st.series_id, st.tag_id, st.slot, st.deleted_at
            FROM series_tags st
            JOIN recurring_series rs ON st.series_id = rs.id
            WHERE rs.user_id = %s AND st.synced_at > %s
        """,
    },
]


def lambda_handler(event, context):
    try:
        user_id = ensure_user(event)
    except PermissionError as e:
        return error(str(e), 401)

    try:
        body = json.loads(event.get("body", "{}"))
    except (json.JSONDecodeError, TypeError):
        return error("Invalid JSON body")

    device_id = body.get("device_id")
    since_str = body.get("since")

    if not device_id:
        return error("device_id is required")

    # Parse since timestamp — default to epoch if not provided.
    if since_str:
        try:
            since = datetime.fromisoformat(since_str)
            if since.tzinfo is None:
                since = since.replace(tzinfo=timezone.utc)
        except ValueError:
            return error("Invalid since timestamp")
    else:
        since = datetime(2000, 1, 1, tzinfo=timezone.utc)

    try:
        changes = []
        for table_def in PULL_TABLES:
            # Every PULL_TABLES query is now `(user_id, since)` — no
            # more variable-arity for tables that previously also
            # filtered on ended_at, since synced_at covers all writes.
            rows = execute(table_def["query"], (user_id, since))

            for row in rows:
                change = {
                    "table": table_def["name"],
                    "data": dict(row),
                    "deleted": row.get("deleted_at") is not None,
                }
                # Set id for single-PK tables.
                if "id" in row:
                    change["id"] = row["id"]
                changes.append(change)

        # Update sync cursor.
        now = datetime.now(timezone.utc)
        execute(
            """
            INSERT INTO sync_cursors (user_id, device_id, last_synced)
            VALUES (%s, %s, %s)
            ON CONFLICT (user_id, device_id)
            DO UPDATE SET last_synced = EXCLUDED.last_synced
            """,
            (user_id, device_id, now),
        )

        commit()
    except Exception:
        rollback()
        logger.exception("sync_pull failed")
        return error("Internal server error", 500)

    return success({
        "changes": changes,
        "server_time": server_time(),
    })
