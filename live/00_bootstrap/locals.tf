locals {
  tfstate_bucket_name = "${var.name_prefix}-tfstate"

  # The budget watches the whole account, not only this project.
  budget_name = "account-monthly-cost"

  plan_role_name       = "${var.project}-gha-plan"
  read_only_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"

  # OIDC 'sub' GitHub sends for workflows triggered by pull_request
  plan_role_subjects = ["${var.github_oidc_sub_prefix}:pull_request"]

  # App CI (eks-platform-app): only builds of main may push images. PRs test and build without AWS.
  app_ci_role_name     = "${var.project}-gha-app-ci"
  app_ci_role_subjects = ["${var.github_app_oidc_sub_prefix}:ref:refs/heads/main"]

  # Apply role: only jobs running in the protected environment get this 'sub'
  # Apply role: approved applies (infra) and the unattended nightly destroy (infra-destroy)
  apply_role_name = "${var.project}-gha-apply"
  apply_role_subjects = [
    "${var.github_oidc_sub_prefix}:environment:${var.github_apply_environment}",
    "${var.github_oidc_sub_prefix}:environment:${var.github_destroy_environment}",
  ]

  boundary_name = "${var.project}-boundary"

  # "01_network" → "network": the SSM contract path each CI layer may write (/myeks/network/*)
  ci_contract_paths = [for l in var.ci_applied_layers : replace(l, "/^[0-9]+_/", "")]

  # AWS-managed policies the EKS module attaches (cluster + node roles) and the EBS CSI driver needs.
  # Anything else attached must be one of our own myeks-* policies.
  # Names include the IAM path: some AWS policies live under service-role/ (check with
  # aws iam list-policies --scope AWS --query "Policies[?PolicyName=='<name>'].Arn").
  attachable_aws_policies = [
    "AmazonEKSClusterPolicy",
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonSSMManagedInstanceCore",
    "service-role/AmazonEBSCSIDriverPolicy",
  ]

  # Service-linked roles that EKS, node groups, Spot, ASGs, the ALB controller and RDS create on first use
  service_linked_role_services = [
    "autoscaling.amazonaws.com",
    "eks.amazonaws.com",
    "eks-nodegroup.amazonaws.com",
    "spot.amazonaws.com",
    "elasticloadbalancing.amazonaws.com",
    "rds.amazonaws.com",
  ]

  # ARN building blocks for the apply policy
  account_id = data.aws_caller_identity.current.account_id
  iam_arn    = "arn:${data.aws_partition.current.partition}:iam::${local.account_id}"

  # backend => myeks/backend
  ecr_repository_names = { for r in var.ecr_repositories : r => "${var.project}/${r}" }
}
