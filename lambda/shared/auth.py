"""JWT/Cognito helpers for Lambda functions."""

from shared.db import get_connection, commit


def get_user_id(event):
    """Extract Cognito user ID (sub) from API Gateway v2 JWT authorizer.

    API Gateway v2 with a JWT authorizer puts the decoded claims in
    event["requestContext"]["authorizer"]["jwt"]["claims"].
    """
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

    Also ensures the user row exists in the database (auto-created
    on first sync from the Cognito JWT claims). The user INSERT is
    committed immediately so it persists even if the sync transaction
    rolls back.
    """
    user_id = get_user_id(event)
    if not user_id:
        raise PermissionError("Missing or invalid authorization")

    email = get_email(event)

    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO users (id, email) VALUES (%s, %s) "
            "ON CONFLICT (id) DO NOTHING",
            (user_id, email),
        )
    # Commit the user row immediately so it's visible to
    # subsequent FK-dependent inserts even if the outer
    # sync transaction fails and rolls back.
    commit()

    return user_id
