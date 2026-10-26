#!/usr/bin/env bash
# Takes a dated snapshot of the prod database (myeks-prod-YYYYMMDD-HHMM), waits until it is
# available, then deletes all but the newest $KEEP. Run before destroying live/04_data:
# the next apply restores the newest snapshot (scripts/latest-db-snapshot.sh).
# No database = nothing to do (exit 0). Exit 2 = a query failed.
set -euo pipefail

PROJECT="${PROJECT:-myeks}"
KEEP="${KEEP:-3}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
DB="$PROJECT-prod"

if ! out=$(aws rds describe-db-instances --db-instance-identifier "$DB" \
  --query 'DBInstances[0].DBInstanceStatus' --output text 2>&1); then
  if grep -q DBInstanceNotFound <<< "$out"; then
    echo "No database $DB: nothing to snapshot"
    exit 0
  fi
  echo "ERROR describe $DB: $out" >&2
  exit 2
fi

# A snapshot can only start from "available" (not during a backup or modification)
aws rds wait db-instance-available --db-instance-identifier "$DB"

snap="$DB-$(date -u +%Y%m%d-%H%M)"
aws rds create-db-snapshot --db-instance-identifier "$DB" --db-snapshot-identifier "$snap" > /dev/null
echo "Creating snapshot $snap ..."
aws rds wait db-snapshot-available --db-snapshot-identifier "$snap"
echo "Snapshot $snap available"

old=$(aws rds describe-db-snapshots --db-instance-identifier "$DB" --snapshot-type manual \
  --query "reverse(sort_by(DBSnapshots[?Status=='available'], &SnapshotCreateTime))[$KEEP:].DBSnapshotIdentifier" \
  --output text)
for s in $old; do
  [ "$s" = "None" ] && continue
  aws rds delete-db-snapshot --db-snapshot-identifier "$s" > /dev/null
  echo "Deleted old snapshot $s (keeping the newest $KEEP)"
done
