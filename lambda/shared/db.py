"""Postgres connection helper for Lambda functions."""

import json
import os

import boto3
import psycopg2
from psycopg2.extras import RealDictCursor

_conn = None


def get_connection():
    """Return a reusable Postgres connection (cached across warm invocations)."""
    global _conn
    if _conn is not None and not _conn.closed:
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
