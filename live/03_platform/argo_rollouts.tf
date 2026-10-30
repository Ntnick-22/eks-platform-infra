# Argo Rollouts (gitops apps/argo-rollouts.yaml) verifies canary steps against AWS
# (--aws-verify-target-group): after each setWeight it checks that the ALB rules really carry
# the weights, and before the old ReplicaSet goes it checks that the target group has the new
# pod IPs. The ALB controller applies weights asynchronously: without this, a canary analysis
# could pass while the canary received no traffic at all. Read-only ELB access, as listed in
# the Argo Rollouts ALB docs (these Describe calls have no resource-level scoping, hence "*").
data "aws_iam_policy_document" "argo_rollouts" {
  statement {
    sid = "VerifyTargetGroups"
    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
    resources = ["*"]
  }
}

module "argo_rollouts_role" {
  source = "../../modules/pod_identity_role"

  name                     = "${var.project}-argo-rollouts"
  permissions_boundary_arn = data.aws_ssm_parameter.permissions_boundary_arn.insecure_value
  inline_policy_json       = data.aws_iam_policy_document.argo_rollouts.json

  association = {
    cluster_name    = data.aws_eks_cluster.this.name
    namespace       = "argo-rollouts"
    service_account = "argo-rollouts" # the chart's default name, pinned in apps/argo-rollouts.yaml
  }
}
