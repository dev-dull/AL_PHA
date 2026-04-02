"""HTTP response helpers."""

import json
from datetime import datetime, timezone


def success(body, status=200):
    """Return a JSON success response."""
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=_serialize),
    }


def error(message, status=400):
    """Return a JSON error response."""
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": message}),
    }


def server_time():
    """Return current UTC time as ISO string (used in sync responses)."""
    return datetime.now(timezone.utc).isoformat()


def _serialize(obj):
    """JSON serializer for objects not serializable by default.

    Converts datetime to UTC epoch seconds (integer) so the Flutter
    client can store them directly in SQLite without conversion.
    """
    if isinstance(obj, datetime):
        return int(obj.replace(tzinfo=timezone.utc).timestamp())
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
