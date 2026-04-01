"""POST /migrate/upload — store an encrypted migration blob in S3."""

import json
import logging
import os
import secrets
import string

import boto3

from shared.response import error, success

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
BUCKET = os.environ.get("S3_BUCKET", "")
CODE_LENGTH = 6
CODE_ALPHABET = string.ascii_uppercase + string.digits
MAX_BODY_SIZE = 50 * 1024 * 1024  # 50 MB limit


def _generate_code():
    """Generate a random 6-character alphanumeric transfer code."""
    return "".join(secrets.choice(CODE_ALPHABET) for _ in range(CODE_LENGTH))


def lambda_handler(event, context):
    # No auth required — migration is anonymous.
    body = event.get("body", "")
    is_base64 = event.get("isBase64Encoded", False)

    if not body:
        return error("Request body is required")

    # API Gateway v2 may base64-encode binary bodies.
    if is_base64:
        import base64
        body_bytes = base64.b64decode(body)
    else:
        body_bytes = body.encode("utf-8") if isinstance(body, str) else body

    if len(body_bytes) > MAX_BODY_SIZE:
        return error(f"Body exceeds {MAX_BODY_SIZE // (1024*1024)} MB limit")

    # Generate a unique transfer code.
    # Retry if the code already exists (astronomically unlikely).
    for _ in range(10):
        code = _generate_code()
        key = f"migrations/{code}.json.enc"
        try:
            s3.head_object(Bucket=BUCKET, Key=key)
            continue  # Code collision, retry.
        except s3.exceptions.ClientError:
            break  # Code is available.
    else:
        return error("Failed to generate unique transfer code", 500)

    try:
        s3.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=body_bytes,
            ContentType="application/octet-stream",
        )
    except Exception:
        logger.exception("S3 upload failed")
        return error("Failed to store migration data", 500)

    logger.info("Migration uploaded: code=%s, size=%d", code, len(body_bytes))

    return success({
        "code": code,
        "expires_in_hours": 24,
    }, status=201)
