#!/usr/bin/env bash
# Finds paid resources of the daily stack that still exist.
#
#   scripts/leftover-check.sh k8s   before destroying 02_eks: AWS resources Kubernetes created
#                                   (ALBs from Ingresses, their DNS records, EBS volumes from PVCs). Terraform does not
#                                   know them, so they block the VPC delete and keep costing money.
#   scripts/leftover-check.sh all   after the destroy: everything of the daily stack
#
# Exit codes: 0 = clean · 1 = leftovers found · 2 = a query failed (result unknown: never report "clean")
#             64 = wrong usage
# Same script in the nightly workflow and on the laptop. Needs read-only AWS access.
set -euo pipefail

usage() { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; } # the header comment above is the help text

MODE="${1:-all}"
case "$MODE" in
  -h | --help) usage; exit 0 ;;
  k8s | all) ;;
  *) # an unknown mode must not silently run fewer checks and report "clean"
    echo "unknown mode: $MODE" >&2
    usage >&2
    exit 64
    ;;
esac

PROJECT="${PROJECT:-myeks}"
CLUSTER="${CLUSTER:-$PROJECT}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
found=0
failed=0

# check "<label>" <command...>
# Runs the command itself instead of receiving its output as an argument: a failing
# "$(cmd)" used as an argument does NOT trigger set -e, so an AccessDenied would look "ok".
check() {
  local label=$1 out
  shift
  if ! out=$("$@" 2>&1); then
    echo "ERROR     $label: query failed: $out" >&2 # stderr: stays visible when stdout is piped
    failed=1
  elif [ -n "$out" ] && [ "$out" != "None" ]; then # --output text prints "None" for null
    echo "LEFTOVER  $label: $out"
    found=1
  else
    echo "ok        $label"
  fi
}

# ── Created by Kubernetes controllers ────────────────────────────────────────
check "load balancers (AWS LB Controller)" aws resourcegroupstaggingapi get-resources \
  --tag-filters "Key=elbv2.k8s.aws/cluster,Values=$CLUSTER" \
  --resource-type-filters elasticloadbalancing:loadbalancer \
  --query 'ResourceTagMappingList[].ResourceARN' --output text

# Records ExternalDNS created under the platform domain (ALB aliases + owner TXT). The ACM
# validation CNAMEs there are persistent (00_bootstrap), so CNAMEs are not counted.
platform_dns_records() {
  local zone domain
  zone=$(aws ssm get-parameter --name "/$PROJECT/bootstrap/hosted_zone_id" --query Parameter.Value --output text) || return 1
  domain=$(aws ssm get-parameter --name "/$PROJECT/bootstrap/platform_domain" --query Parameter.Value --output text) || return 1
  aws route53 list-resource-record-sets --hosted-zone-id "$zone" \
    --query "ResourceRecordSets[?(Name=='$domain.' || ends_with(Name, '.$domain.')) && Type!='CNAME'].[Name,Type]" \
    --output text
}
check "DNS records (ExternalDNS)" platform_dns_records

check "EBS volumes (EBS CSI driver)" aws ec2 describe-volumes \
  --filters "Name=tag-key,Values=kubernetes.io/cluster/$CLUSTER" \
  --query 'Volumes[].VolumeId' --output text

if [ "$MODE" = "all" ]; then
  # ── Created by Terraform (should be gone after destroy) ─────────────────────
  check "EKS cluster" aws eks list-clusters --query "clusters[?@=='$CLUSTER']" --output text

  check "EC2 instances (nodes, NAT)" aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=$PROJECT" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[].InstanceId' --output text

  check "VPC" aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --query 'Vpcs[].VpcId' --output text

  check "network interfaces" aws ec2 describe-network-interfaces \
    --filters "Name=tag:Project,Values=$PROJECT" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text

  check "control plane log group" aws logs describe-log-groups \
    --log-group-name-prefix "/aws/eks/$CLUSTER/" --query 'logGroups[].logGroupName' --output text

  # The dated snapshots are kept on purpose (prod data); the instance must be gone
  check "RDS instance (04_data)" aws rds describe-db-instances \
    --query "DBInstances[?DBInstanceIdentifier=='$PROJECT-prod'].DBInstanceIdentifier" --output text

  check "prod DB secret (04_data)" aws secretsmanager list-secrets \
    --filters "Key=name,Values=$PROJECT/prod/" --query 'SecretList[].Name' --output text

  for layer in network eks data; do
    check "SSM contract /$PROJECT/$layer" aws ssm get-parameters-by-path \
      --path "/$PROJECT/$layer" --query 'Parameters[].Name' --output text
  done
fi

if [ "$failed" -ne 0 ]; then
  echo "::error::Leftover check could not run every query (mode: $MODE). Result unknown: check AWS manually."
  exit 2
fi
if [ "$found" -ne 0 ]; then
  echo "::error::Leftover resources found (mode: $MODE). They cost money or block the VPC delete."
  exit 1
fi
echo "No leftovers (mode: $MODE)."
