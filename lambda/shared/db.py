"""Postgres connection helper for Lambda functions."""

import json
import logging
import os
from contextlib import contextmanager

import boto3
import psycopg2
import psycopg2.extensions
from psycopg2 import sql
from psycopg2.extras import RealDictCursor

logger = logging.getLogger()

_conn = None
# Set to True while inside a `savepoint()` block so the auto-rollback
# in get_connection() doesn't fire on INERROR — we want a ROLLBACK TO
# SAVEPOINT instead, which preserves the surrounding transaction.
_in_savepoint = False


def get_connection():
    """Return a reusable Postgres connection (cached across warm invocations)."""
    global _conn

    if _conn is not None:
        if _conn.closed:
            logger.info("DB connection closed, reconnecting")
            _conn = None
        elif not _in_savepoint:
            # Reset if in error or aborted transaction state. Skipped
            # while inside a savepoint block — there the caller will
            # issue ROLLBACK TO SAVEPOINT itself, and we must not
            # discard the outer transaction's already-committed work.
            status = _conn.get_transaction_status()
            if status == psycopg2.extensions.TRANSACTION_STATUS_INERROR:
                logger.info("DB connection in error state, rolling back")
                _conn.rollback()
            elif status == psycopg2.extensions.TRANSACTION_STATUS_UNKNOWN:
                logger.info("DB connection in unknown state, reconnecting")
                _conn = None

    if _conn is not None:
        return _conn

    secret_arn = os.environ["DB_SECRET_ARN"]
    host = os.environ["DB_HOST"]
    port = os.environ.get("DB_PORT", "5432")
    dbname = os.environ.get("DB_NAME", "alpha")

    client = boto3.client("secretsmanager")
    resp = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(resp["SecretString"])

    _conn = psycopg2.connect(
        host=host,
        port=port,
        dbname=dbname,
        user=secret["username"],
        password=secret["password"],
        cursor_factory=RealDictCursor,
        connect_timeout=5,
    )
    _conn.autocommit = False
    logger.info("DB connected to %s:%s/%s", host, port, dbname)
    return _conn


def execute(query, params=None):
    """Execute a query and return all rows."""
    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute(query, params)
        if cur.description:
            return cur.fetchall()
        return []


def execute_one(query, params=None):
    """Execute a query and return a single row or None."""
    rows = execute(query, params)
    return rows[0] if rows else None


def commit():
    """Commit the current transaction."""
    get_connection().commit()


def rollback():
    """Rollback the current transaction."""
    conn = get_connection()
    if not conn.closed:
        conn.rollback()


@contextmanager
def savepoint(name):
    """Per-row error containment via Postgres SAVEPOINTs.

    On exception inside the block, rolls back to the savepoint and
    re-raises — preserving every prior write in the surrounding
    transaction. The caller is expected to catch the exception, log
    it, and continue processing the next row. Without this, a single
    failing INSERT (e.g. a unique-constraint violation) would put
    the connection into INERROR state and the next get_connection()
    would discard the entire batch.

    Names must be valid identifiers. Caller's responsibility to make
    them unique within a single transaction (typical pattern: append
    a loop counter).
    """
    global _in_savepoint
    sp = sql.Identifier(name)
    execute(sql.SQL("SAVEPOINT {}").format(sp))
    _in_savepoint = True
    try:
        yield
    except Exception:
        # The connection is in INERROR — but with _in_savepoint True,
        # get_connection() won't auto-rollback on us. ROLLBACK TO
        # SAVEPOINT clears the error and leaves the outer transaction
        # intact for the next iteration.
        execute(sql.SQL("ROLLBACK TO SAVEPOINT {}").format(sp))
        raise
    else:
        execute(sql.SQL("RELEASE SAVEPOINT {}").format(sp))
    finally:
        _in_savepoint = False
