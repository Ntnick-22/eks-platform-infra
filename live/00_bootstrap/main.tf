module "budget" {
  source = "../../modules/budget"

  name         = local.budget_name
  limit_usd    = var.budget_limit_usd
  alert_emails = var.budget_alert_emails
}

module "tfstate_bucket" {
  source = "../../modules/s3_bucket_secure"

  bucket_name                        = local.tfstate_bucket_name
  noncurrent_version_expiration_days = var.tfstate_noncurrent_version_days
}

module "gha_plan_role" {
  source = "../../modules/github_oidc_role"

  name                = local.plan_role_name
  oidc_provider_arn   = data.aws_iam_openid_connect_provider.github.arn
  subjects            = local.plan_role_subjects
  managed_policy_arns = [local.read_only_policy_arn]
  inline_policies = {
    tfstate-lock = data.aws_iam_policy_document.tfstate_lock.json
  }
}

module "ecr" {
  source   = "../../modules/ecr_repository"
  for_each = local.ecr_repository_names

  name = each.value
}
