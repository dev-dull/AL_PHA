"""JWT/Cognito helpers for Lambda functions."""


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


def ensure_user(event):
    """Return user_id or raise if not authenticated."""
    user_id = get_user_id(event)
    if not user_id:
        raise PermissionError("Missing or invalid authorization")
    return user_id
