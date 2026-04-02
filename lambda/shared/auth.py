"""JWT/Cognito helpers for Lambda functions."""

from shared.db import execute


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
    on first sync from the Cognito JWT claims).
    """
    user_id = get_user_id(event)
    if not user_id:
        raise PermissionError("Missing or invalid authorization")

    email = get_email(event)

    # Upsert user row — creates on first sync, no-op after.
    execute(
        """
        INSERT INTO users (id, email)
        VALUES (%s, %s)
        ON CONFLICT (id) DO NOTHING
        """,
        (user_id, email),
    )

    return user_id
