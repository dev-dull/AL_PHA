"""JWT/Cognito helpers for Lambda functions."""

import logging

from shared.db import get_connection

logger = logging.getLogger()


def get_user_id(event):
    """Extract Cognito user ID (sub) from API Gateway v2 JWT authorizer."""
    try:
        claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
        return claims["sub"]
    except (KeyError, TypeError):
        return None


def get_email(event):
    """Extract email from JWT claims."""
    try:
        claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
        return claims.get("email", "")
    except (KeyError, TypeError):
        return ""


def ensure_user(event):
    """Return user_id or raise if not authenticated.

    Ensures the user row exists via a dedicated autocommit connection
    so the row persists regardless of the sync transaction outcome.
    """
    user_id = get_user_id(event)
    if not user_id:
        raise PermissionError("Missing or invalid authorization")

    email = get_email(event)

    conn = get_connection()
    old_autocommit = conn.autocommit
    try:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO users (id, email) VALUES (%s, %s) "
                "ON CONFLICT (id) DO NOTHING",
                (user_id, email),
            )
        logger.info("ensure_user: %s (%s)", user_id[:8], email)
    finally:
        conn.autocommit = old_autocommit

    return user_id
