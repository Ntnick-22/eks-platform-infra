locals {
  tfstate_bucket_name = "${var.name_prefix}-tfstate"

  # The budget watches the whole account, not only this project.
  budget_name = "account-monthly-cost"

  plan_role_name       = "${var.project}-gha-plan"
  read_only_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"

  # OIDC 'sub' GitHub sends for workflows triggered by pull_request
  plan_role_subjects = ["${var.github_oidc_sub_prefix}:pull_request"]

  # Apply role: only jobs running in the protected environment get this 'sub'
  apply_role_name     = "${var.project}-gha-apply"
  apply_role_subjects = ["${var.github_oidc_sub_prefix}:environment:${var.github_apply_environment}"]

  # ARN building blocks for the apply policy
  account_id = data.aws_caller_identity.current.account_id
  iam_arn    = "arn:${data.aws_partition.current.partition}:iam::${local.account_id}"

  # backend => myeks/backend
  ecr_repository_names = { for r in var.ecr_repositories : r => "${var.project}/${r}" }
}
