#!/usr/bin/env bash
# Prints the newest available snapshot of the prod database (myeks-prod-YYYYMMDD-HHMM), or nothing.
# live/04_data restores from it; no output = no snapshot yet, so 04_data creates an empty database.
#
#   SNAP=$(scripts/latest-db-snapshot.sh) && TF_VAR_restore_snapshot_identifier="$SNAP" terraform apply
#
# A failed query exits non-zero instead of printing nothing: an AccessDenied must never turn
# into "no snapshot" and bring prod up empty.
set -euo pipefail

PROJECT="${PROJECT:-myeks}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"

newest=$(aws rds describe-db-snapshots --db-instance-identifier "$PROJECT-prod" --snapshot-type manual \
  --query "reverse(sort_by(DBSnapshots[?Status=='available'], &SnapshotCreateTime))[0].DBSnapshotIdentifier" \
  --output text)
[ "$newest" = "None" ] && newest="" # --output text prints "None" for null
echo "$newest"
