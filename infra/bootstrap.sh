#!/usr/bin/env bash
# Bootstrap Terraform backend resources (run once, manually).
# These resources are NOT managed by Terraform itself.
set -euo pipefail

ACCOUNT_ID="773469078444"
REGION="us-west-2"
STATE_BUCKET="alpha-terraform-state-${ACCOUNT_ID}"
LOCK_TABLE="alpha-terraform-locks"

echo "Creating S3 state bucket: ${STATE_BUCKET}"
aws s3api create-bucket \
  --bucket "${STATE_BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}" \
  2>/dev/null || echo "  (bucket already exists)"

aws s3api put-bucket-versioning \
  --bucket "${STATE_BUCKET}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "${STATE_BUCKET}" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket "${STATE_BUCKET}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Creating DynamoDB lock table: ${LOCK_TABLE}"
aws dynamodb create-table \
  --table-name "${LOCK_TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" \
  2>/dev/null || echo "  (table already exists)"

echo ""
echo "Done. Now run:"
echo "  cd infra && terraform init"
