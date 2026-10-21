#!/usr/bin/env bash
# Finds paid resources of the daily stack that still exist. Exit 1 if any are found.
#
#   scripts/leftover-check.sh k8s   before destroying 02_eks: AWS resources Kubernetes created
#                                   (ALBs from Ingresses, EBS volumes from PVCs). Terraform does not
#                                   know them, so they block the VPC delete and keep costing money.
#   scripts/leftover-check.sh all   after the destroy: everything of the daily stack
#
# Same script in the nightly workflow and on the laptop. Needs read-only AWS access.
set -euo pipefail

MODE="${1:-all}"
PROJECT="${PROJECT:-myeks}"
CLUSTER="${CLUSTER:-$PROJECT}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
found=0

check() { # check "<label>" "<output of an aws query>"
  if [ -n "$2" ] && [ "$2" != "None" ]; then
    echo "LEFTOVER  $1: $2"
    found=1
  else
    echo "ok        $1"
  fi
}

# ── Created by Kubernetes controllers ────────────────────────────────────────
check "load balancers (AWS LB Controller)" "$(aws resourcegroupstaggingapi get-resources \
  --tag-filters "Key=elbv2.k8s.aws/cluster,Values=$CLUSTER" \
  --resource-type-filters elasticloadbalancing:loadbalancer \
  --query 'ResourceTagMappingList[].ResourceARN' --output text)"

check "EBS volumes (EBS CSI driver)" "$(aws ec2 describe-volumes \
  --filters "Name=tag-key,Values=kubernetes.io/cluster/$CLUSTER" \
  --query 'Volumes[].VolumeId' --output text)"

if [ "$MODE" = "all" ]; then
  # ── Created by Terraform (should be gone after destroy) ─────────────────────
  check "EKS cluster" "$(aws eks list-clusters --query "clusters[?@=='$CLUSTER']" --output text)"

  check "EC2 instances (nodes, NAT)" "$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=$PROJECT" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[].InstanceId' --output text)"

  check "VPC" "$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --query 'Vpcs[].VpcId' --output text)"

  check "network interfaces" "$(aws ec2 describe-network-interfaces \
    --filters "Name=tag:Project,Values=$PROJECT" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text)"

  check "control plane log group" "$(aws logs describe-log-groups \
    --log-group-name-prefix "/aws/eks/$CLUSTER/" --query 'logGroups[].logGroupName' --output text)"

  for layer in network eks; do
    check "SSM contract /$PROJECT/$layer" "$(aws ssm get-parameters-by-path \
      --path "/$PROJECT/$layer" --query 'Parameters[].Name' --output text)"
  done
fi

if [ "$found" -ne 0 ]; then
  echo "::error::Leftover resources found (mode: $MODE). They cost money or block the VPC delete."
  exit 1
fi
echo "No leftovers (mode: $MODE)."
