"""POST /sync/push — accept changes from a device."""

import json
import logging
from datetime import datetime, timezone

from shared.auth import ensure_user
from shared.db import commit, execute, execute_one, rollback
from shared.response import error, server_time, success

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Tables the client can push, in dependency order.
# Maps client table name → (pg table name, id column, has user_id).
SYNCABLE_TABLES = {
    "tags":             ("tags",             "id", True),
    "boards":           ("boards",           "id", True),
    "board_columns":    ("board_columns",    "id", False),
    "tasks":            ("tasks",            "id", True),
    "markers":          ("markers",          "id", False),
    "task_notes":       ("task_notes",       "id", False),
    "task_tags":         None,  # composite key, handled separately
    "recurring_series": ("recurring_series", "id", True),
    "series_tags":       None,  # composite key, handled separately
}

# Columns for each table (excluding user_id and deleted_at, which
# are handled by the sync logic).
TABLE_COLUMNS = {
    "boards": [
        "id", "name", "type", "created_at", "updated_at",
        "archived", "week_start",
    ],
    "board_columns": [
        "id", "board_id", "label", "position", "type",
    ],
    "tasks": [
        "id", "board_id", "title", "description", "state",
        "priority", "position", "created_at", "updated_at",
        "completed_at", "deadline", "migrated_from_board_id",
        "migrated_from_task_id", "is_event", "scheduled_time",
        "recurrence_rule", "series_id",
    ],
    "markers": [
        "id", "task_id", "column_id", "board_id", "symbol",
        "updated_at",
    ],
    "task_notes": [
        "id", "task_id", "content", "created_at", "updated_at",
    ],
    "tags": [
        "id", "name", "color", "position", "created_at",
    ],
    "recurring_series": [
        "id", "title", "description", "priority", "recurrence_rule",
        "is_event", "scheduled_time", "created_at", "ended_at",
    ],
}


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
    changes = body.get("changes", [])

    if not device_id:
        return error("device_id is required")
    if not isinstance(changes, list):
        return error("changes must be an array")

    accepted = 0
    rejected = 0

    try:
        for change in changes:
            table = change.get("table")
            row_id = change.get("id")
            data = change.get("data", {})
            updated_at = change.get("updated_at")
            deleted = change.get("deleted", False)

            if table not in SYNCABLE_TABLES:
                logger.warning("Unknown table: %s", table)
                rejected += 1
                continue

            if not row_id and table not in ("task_tags", "series_tags"):
                rejected += 1
                continue

            try:
                ts = datetime.fromisoformat(updated_at)
                if ts.tzinfo is None:
                    ts = ts.replace(tzinfo=timezone.utc)
            except (ValueError, TypeError):
                rejected += 1
                continue

            if table == "task_tags":
                if _upsert_junction(
                    "task_tags", "task_id", "tag_id",
                    data, ts, deleted, user_id,
                ):
                    accepted += 1
                else:
                    rejected += 1
            elif table == "series_tags":
                if _upsert_junction(
                    "series_tags", "series_id", "tag_id",
                    data, ts, deleted, user_id,
                ):
                    accepted += 1
                else:
                    rejected += 1
            else:
                pg_table, id_col, has_user_id = SYNCABLE_TABLES[table]
                if _upsert_row(
                    pg_table, id_col, row_id, data, ts,
                    deleted, user_id if has_user_id else None,
                    table,
                ):
                    accepted += 1
                else:
                    rejected += 1

        # Update sync cursor for this device.
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
        logger.exception("sync_push failed")
        return error("Internal server error", 500)

    return success({
        "accepted": accepted,
        "rejected": rejected,
        "server_time": server_time(),
    })


# Tables that use created_at instead of updated_at for timestamps.
_CREATED_AT_TABLES = {"tags", "recurring_series"}


def _upsert_row(table, id_col, row_id, data, updated_at,
                 deleted, user_id, client_table):
    """Upsert a single row. Returns True if accepted."""
    ts_col = "created_at" if client_table in _CREATED_AT_TABLES else "updated_at"

    existing = execute_one(
        f"SELECT {ts_col} as ts, deleted_at FROM {table} WHERE {id_col} = %s",
        (row_id,),
    )

    if deleted:
        if existing:
            execute(
                f"UPDATE {table} SET deleted_at = %s WHERE {id_col} = %s",
                (updated_at, row_id),
            )
        return True

    if existing:
        server_ts = existing["ts"]
        if server_ts and updated_at <= server_ts:
            return False  # Server wins tie
        return _update_row(table, id_col, row_id, data, user_id, client_table)
    else:
        return _insert_row(table, id_col, row_id, data, user_id, client_table)


def _insert_row(table, id_col, row_id, data, user_id, client_table):
    """Insert a new row."""
    columns = TABLE_COLUMNS.get(client_table, [])
    col_names = []
    values = []

    for col in columns:
        if col in data:
            col_names.append(col)
            values.append(data[col])
        elif col == "id":
            col_names.append(col)
            values.append(row_id)

    if user_id:
        col_names.append("user_id")
        values.append(user_id)

    if not col_names:
        return False

    placeholders = ", ".join(["%s"] * len(values))
    col_str = ", ".join(col_names)

    execute(
        f"INSERT INTO {table} ({col_str}) VALUES ({placeholders})",
        values,
    )
    return True


def _update_row(table, id_col, row_id, data, user_id, client_table):
    """Update an existing row (last-write-wins)."""
    columns = TABLE_COLUMNS.get(client_table, [])
    sets = []
    values = []

    for col in columns:
        if col == "id":
            continue
        if col in data:
            sets.append(f"{col} = %s")
            values.append(data[col])

    if not sets:
        return False

    # Clear deleted_at on update (un-delete if previously soft-deleted).
    sets.append("deleted_at = NULL")

    values.append(row_id)
    set_str = ", ".join(sets)

    execute(
        f"UPDATE {table} SET {set_str} WHERE {id_col} = %s",
        values,
    )
    return True


def _upsert_junction(table, key1, key2, data, updated_at, deleted, user_id):
    """Upsert a junction table row (composite primary key)."""
    k1 = data.get(key1)
    k2 = data.get(key2)
    if not k1 or not k2:
        return False

    existing = execute_one(
        f"SELECT deleted_at FROM {table} WHERE {key1} = %s AND {key2} = %s",
        (k1, k2),
    )

    if deleted:
        if existing:
            execute(
                f"UPDATE {table} SET deleted_at = %s "
                f"WHERE {key1} = %s AND {key2} = %s",
                (updated_at, k1, k2),
            )
        return True

    slot = data.get("slot", 0)

    if existing:
        execute(
            f"UPDATE {table} SET slot = %s, deleted_at = NULL "
            f"WHERE {key1} = %s AND {key2} = %s",
            (slot, k1, k2),
        )
    else:
        execute(
            f"INSERT INTO {table} ({key1}, {key2}, slot) VALUES (%s, %s, %s)",
            (k1, k2, slot),
        )
    return True
