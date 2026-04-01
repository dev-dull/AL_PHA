"""POST /migrate/download/{code} — retrieve and delete a migration blob."""

import base64
import logging
import os
import re

import boto3
from botocore.exceptions import ClientError

from shared.response import error

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
BUCKET = os.environ.get("S3_BUCKET", "")
CODE_PATTERN = re.compile(r"^[A-Z0-9]{6}$")


def lambda_handler(event, context):
    # No auth required — the transfer code is the secret.
    # Extract code from path parameter.
    code = (event.get("pathParameters") or {}).get("code", "")

    if not code or not CODE_PATTERN.match(code):
        return error("Invalid transfer code")

    key = f"migrations/{code}.json.enc"

    try:
        resp = s3.get_object(Bucket=BUCKET, Key=key)
        body_bytes = resp["Body"].read()
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            return error("Transfer code not found or expired", 404)
        logger.exception("S3 download failed")
        return error("Failed to retrieve migration data", 500)

    # Delete the object — one-time use.
    try:
        s3.delete_object(Bucket=BUCKET, Key=key)
    except Exception:
        logger.warning("Failed to delete migration object: %s", key)

    logger.info("Migration downloaded: code=%s, size=%d", code, len(body_bytes))

    # Return the binary blob as base64-encoded response.
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/octet-stream",
        },
        "body": base64.b64encode(body_bytes).decode("utf-8"),
        "isBase64Encoded": True,
    }
