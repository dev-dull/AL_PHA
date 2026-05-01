"""POST /sync/push — accept changes from a device."""

import json
import logging
from datetime import datetime, timezone

from psycopg2 import sql

from shared.auth import ensure_user
from shared.db import commit, execute, execute_one, rollback
from shared.response import error, server_time, success

# Columns that are timestamps — values from SQLite may arrive
# as epoch seconds (integers) and need conversion to datetime.
_TIMESTAMP_COLUMNS = {
    "created_at", "updated_at", "completed_at", "deadline",
    "week_start", "ended_at",
}

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
        "id", "name", "color", "position", "created_at", "updated_at",
    ],
    "recurring_series": [
        "id", "title", "description", "priority", "recurrence_rule",
        "is_event", "scheduled_time", "created_at", "ended_at",
    ],
}

# Pre-validated set of allowed table and column identifiers.
# Any identifier used in SQL must be in this set.
_VALID_IDENTIFIERS = set()
for _tbl, _cols in TABLE_COLUMNS.items():
    _VALID_IDENTIFIERS.add(_tbl)
    _VALID_IDENTIFIERS.update(_cols)
_VALID_IDENTIFIERS.update({
    "user_id", "deleted_at", "ts", "slot",
    "task_id", "tag_id", "series_id",
    # Server-stamped change-detection cursor (V003). Set to NOW() on
    # every insert / update / soft-delete by the helpers below; pull
    # filters on this instead of the client-supplied updated_at.
    "synced_at",
    # Junction tables — handled by _upsert_junction, so not in
    # TABLE_COLUMNS, but their names still need to be valid identifiers.
    "task_tags", "series_tags",
})


def _ident(name):
    """Return a safe SQL identifier, rejecting unknown names."""
    if name not in _VALID_IDENTIFIERS:
        raise ValueError(f"Unknown SQL identifier: {name}")
    return sql.Identifier(name)


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

    # Sort changes by dependency order so FK constraints are
    # satisfied: parents before children.
    _TABLE_ORDER = {
        "tags": 0, "boards": 1, "board_columns": 2,
        "recurring_series": 3, "tasks": 4, "markers": 5,
        "task_notes": 6, "task_tags": 7, "series_tags": 8,
    }
    changes.sort(key=lambda c: _TABLE_ORDER.get(c.get("table", ""), 99))

    try:
        logger.info("Processing %d changes for user %s, device %s",
                    len(changes), user_id, device_id)

        for i, change in enumerate(changes):
            table = change.get("table")
            row_id = change.get("id")
            data = change.get("data", {})
            updated_at = change.get("updated_at")
            deleted = change.get("deleted", False)

            logger.info("Change %d/%d: table=%s id=%s deleted=%s",
                        i + 1, len(changes), table,
                        str(row_id)[:8] if row_id else "None", deleted)

            if table not in SYNCABLE_TABLES:
                logger.warning("Unknown table: %s", table)
                rejected += 1
                continue

            if not row_id and table not in ("task_tags", "series_tags"):
                logger.warning("Missing id for table %s", table)
                rejected += 1
                continue

            try:
                ts = datetime.fromisoformat(updated_at)
                if ts.tzinfo is None:
                    ts = ts.replace(tzinfo=timezone.utc)
            except (ValueError, TypeError):
                logger.warning("Invalid timestamp: %s", updated_at)
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
                logger.info("  → upsert %s.%s = %s (user_id=%s)",
                            pg_table, id_col, str(row_id)[:8],
                            "yes" if has_user_id else "no")
                try:
                    if _upsert_row(
                        pg_table, id_col, row_id, data, ts,
                        deleted, user_id if has_user_id else None,
                        table,
                    ):
                        accepted += 1
                        logger.info("  → accepted")
                    else:
                        rejected += 1
                        logger.info("  → rejected (server wins)")
                except Exception as row_err:
                    logger.warning("  → skipped: %s", row_err)
                    rejected += 1
                    # Roll back just this statement so the
                    # transaction can continue with the rest.
                    rollback()
                    # Re-create the user row (lost in rollback).
                    ensure_user(event)

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


# Map client table → timestamp column for conflict resolution.
# Tables not listed here have no timestamp — always upsert.
_TIMESTAMP_COL = {
    "boards": "updated_at",
    "tasks": "updated_at",
    "markers": "updated_at",
    "task_notes": "updated_at",
    "tags": "updated_at",
    "recurring_series": "created_at",
    # board_columns has no timestamp — always upsert.
}


def _upsert_row(table, id_col, row_id, data, updated_at,
                 deleted, user_id, client_table):
    """Upsert a single row. Returns True if accepted."""
    ts_col = _TIMESTAMP_COL.get(client_table)

    if ts_col:
        existing = execute_one(
            sql.SQL("SELECT {ts} AS ts, {da} FROM {tbl} WHERE {idc} = %s").format(
                ts=_ident(ts_col),
                da=_ident("deleted_at"),
                tbl=_ident(table),
                idc=_ident(id_col),
            ),
            (row_id,),
        )
    else:
        existing = execute_one(
            sql.SQL("SELECT 1 AS ts FROM {tbl} WHERE {idc} = %s").format(
                tbl=_ident(table),
                idc=_ident(id_col),
            ),
            (row_id,),
        )

    if deleted:
        if existing:
            execute(
                sql.SQL(
                    "UPDATE {tbl} SET {da} = %s, {synced} = NOW() "
                    "WHERE {idc} = %s"
                ).format(
                    tbl=_ident(table),
                    da=_ident("deleted_at"),
                    synced=_ident("synced_at"),
                    idc=_ident(id_col),
                ),
                (updated_at, row_id),
            )
        return True

    if existing:
        if ts_col:
            server_ts = existing["ts"]
            if server_ts and updated_at <= server_ts:
                return False  # Server wins tie
        return _update_row(table, id_col, row_id, data, user_id,
                           client_table)
    else:
        return _insert_row(table, id_col, row_id, data, user_id,
                           client_table)


def _coerce_value(col, value):
    """Convert SQLite epoch-second integers to datetime for Postgres."""
    if col in _TIMESTAMP_COLUMNS and isinstance(value, (int, float)):
        if value == 0:
            return None
        return datetime.fromtimestamp(value, tz=timezone.utc)
    # SQLite booleans arrive as 0/1 integers.
    if col in ("archived", "is_event") and isinstance(value, int):
        return bool(value)
    return value


def _insert_row(table, id_col, row_id, data, user_id, client_table):
    """Insert a new row."""
    columns = TABLE_COLUMNS.get(client_table, [])
    col_idents = []
    values = []

    for col in columns:
        if col in data:
            col_idents.append(_ident(col))
            values.append(_coerce_value(col, data[col]))
        elif col == "id":
            col_idents.append(_ident(col))
            values.append(row_id)

    if user_id:
        col_idents.append(_ident("user_id"))
        values.append(user_id)

    if not col_idents:
        return False

    placeholders = sql.SQL(", ").join([sql.Placeholder()] * len(values))
    col_list = sql.SQL(", ").join(col_idents)

    # synced_at is server-stamped (V003) — every insert sets NOW()
    # so the change-detection cursor on the pull side is consistent
    # across devices regardless of client clock skew.
    execute(
        sql.SQL(
            "INSERT INTO {tbl} ({cols}, {synced}) "
            "VALUES ({phs}, NOW())"
        ).format(
            tbl=_ident(table),
            cols=col_list,
            synced=_ident("synced_at"),
            phs=placeholders,
        ),
        values,
    )
    return True


def _update_row(table, id_col, row_id, data, user_id, client_table):
    """Update an existing row (last-write-wins)."""
    columns = TABLE_COLUMNS.get(client_table, [])
    set_parts = []
    values = []

    for col in columns:
        if col == "id":
            continue
        if col in data:
            set_parts.append(
                sql.SQL("{} = %s").format(_ident(col))
            )
            values.append(_coerce_value(col, data[col]))

    if not set_parts:
        return False

    # Clear deleted_at on update (un-delete if previously soft-deleted).
    set_parts.append(
        sql.SQL("{} = NULL").format(_ident("deleted_at"))
    )
    # Server-stamp synced_at so this update is visible to other
    # devices' next pull regardless of client clock skew (V003).
    set_parts.append(
        sql.SQL("{} = NOW()").format(_ident("synced_at"))
    )

    values.append(row_id)
    set_clause = sql.SQL(", ").join(set_parts)

    execute(
        sql.SQL("UPDATE {tbl} SET {sets} WHERE {idc} = %s").format(
            tbl=_ident(table),
            sets=set_clause,
            idc=_ident(id_col),
        ),
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
        sql.SQL("SELECT {da} FROM {tbl} WHERE {k1} = %s AND {k2} = %s").format(
            da=_ident("deleted_at"),
            tbl=_ident(table),
            k1=_ident(key1),
            k2=_ident(key2),
        ),
        (k1, k2),
    )

    if deleted:
        if existing:
            execute(
                sql.SQL(
                    "UPDATE {tbl} SET {da} = %s, {synced} = NOW() "
                    "WHERE {k1} = %s AND {k2} = %s"
                ).format(
                    tbl=_ident(table),
                    da=_ident("deleted_at"),
                    synced=_ident("synced_at"),
                    k1=_ident(key1),
                    k2=_ident(key2),
                ),
                (updated_at, k1, k2),
            )
        return True

    slot = data.get("slot", 0)

    if existing:
        execute(
            sql.SQL(
                "UPDATE {tbl} SET {s} = %s, {da} = NULL, "
                "{synced} = NOW() "
                "WHERE {k1} = %s AND {k2} = %s"
            ).format(
                tbl=_ident(table),
                s=_ident("slot"),
                da=_ident("deleted_at"),
                synced=_ident("synced_at"),
                k1=_ident(key1),
                k2=_ident(key2),
            ),
            (slot, k1, k2),
        )
    else:
        execute(
            sql.SQL(
                "INSERT INTO {tbl} ({k1}, {k2}, {s}, {synced}) "
                "VALUES (%s, %s, %s, NOW())"
            ).format(
                tbl=_ident(table),
                k1=_ident(key1),
                k2=_ident(key2),
                s=_ident("slot"),
                synced=_ident("synced_at"),
            ),
            (k1, k2, slot),
        )
    return True
