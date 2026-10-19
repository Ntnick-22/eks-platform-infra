locals {
  tfstate_bucket_name = "${var.name_prefix}-tfstate"

  # The budget watches the whole account, not only this project.
  budget_name = "account-monthly-cost"

  plan_role_name       = "${var.project}-gha-plan"
  read_only_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"

  # OIDC 'sub' GitHub sends for workflows triggered by pull_request
  plan_role_subjects = ["${var.github_oidc_sub_prefix}:pull_request"]
}
