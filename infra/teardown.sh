#!/usr/bin/env bash
# Tear down Terraform backend resources created by bootstrap.sh.
# Run AFTER `terraform destroy` has removed all managed resources.
#
# WARNING: This deletes the state bucket (including all versions)
# and the lock table. You will lose all Terraform state history.
set -euo pipefail

ACCOUNT_ID="773469078444"
REGION="us-west-2"
STATE_BUCKET="alpha-terraform-state-${ACCOUNT_ID}"
LOCK_TABLE="alpha-terraform-locks"

read -rp "This will permanently delete the Terraform state bucket and lock table. Continue? [y/N] " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

echo "Deleting all object versions in: ${STATE_BUCKET}"
aws s3api list-object-versions \
  --bucket "${STATE_BUCKET}" \
  --region "${REGION}" \
  --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
  --output json 2>/dev/null \
| jq -c 'select(.Objects != null)' \
| while read -r batch; do
    aws s3api delete-objects \
      --bucket "${STATE_BUCKET}" \
      --region "${REGION}" \
      --delete "${batch}" \
      > /dev/null
  done

echo "Deleting delete markers in: ${STATE_BUCKET}"
aws s3api list-object-versions \
  --bucket "${STATE_BUCKET}" \
  --region "${REGION}" \
  --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
  --output json 2>/dev/null \
| jq -c 'select(.Objects != null)' \
| while read -r batch; do
    aws s3api delete-objects \
      --bucket "${STATE_BUCKET}" \
      --region "${REGION}" \
      --delete "${batch}" \
      > /dev/null
  done

echo "Deleting bucket: ${STATE_BUCKET}"
aws s3api delete-bucket \
  --bucket "${STATE_BUCKET}" \
  --region "${REGION}" \
  2>/dev/null || echo "  (bucket already deleted or not empty)"

echo "Deleting DynamoDB lock table: ${LOCK_TABLE}"
aws dynamodb delete-table \
  --table-name "${LOCK_TABLE}" \
  --region "${REGION}" \
  > /dev/null 2>&1 || echo "  (table already deleted)"

echo ""
echo "Done. Backend resources removed."
