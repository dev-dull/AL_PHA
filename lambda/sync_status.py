"""GET /sync/status — return sync metadata for the authenticated user."""

import logging

from psycopg2 import sql

from shared.auth import ensure_user
from shared.db import execute, execute_one
from shared.response import error, server_time, success

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    try:
        user_id = ensure_user(event)
    except PermissionError as e:
        return error(str(e), 401)

    try:
        # Get all sync cursors for this user's devices.
        cursors = execute(
            """
            SELECT device_id, last_synced
            FROM sync_cursors
            WHERE user_id = %s
            ORDER BY last_synced DESC
            """,
            (user_id,),
        )

        # Count rows per table for this user.
        counts = {}
        for table, col in [
            ("boards", "user_id"),
            ("tasks", "user_id"),
            ("tags", "user_id"),
            ("recurring_series", "user_id"),
        ]:
            row = execute_one(
                sql.SQL(
                    "SELECT COUNT(*) as count FROM {tbl} "
                    "WHERE {col} = %s AND {da} IS NULL"
                ).format(
                    tbl=sql.Identifier(table),
                    col=sql.Identifier(col),
                    da=sql.Identifier("deleted_at"),
                ),
                (user_id,),
            )
            counts[table] = row["count"] if row else 0

    except Exception:
        logger.exception("sync_status failed")
        return error("Internal server error", 500)

    return success({
        "user_id": user_id,
        "devices": [
            {"device_id": c["device_id"], "last_synced": c["last_synced"]}
            for c in cursors
        ],
        "row_counts": counts,
        "server_time": server_time(),
    })
