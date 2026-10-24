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

module "gha_apply_role" {
  source = "../../modules/github_oidc_role"

  name                = local.apply_role_name
  oidc_provider_arn   = data.aws_iam_openid_connect_provider.github.arn
  subjects            = local.apply_role_subjects
  managed_policy_arns = [local.read_only_policy_arn] # plan needs to read everything it refreshes
  inline_policies = {
    ci-apply = data.aws_iam_policy_document.ci_apply.json
  }
}

module "permissions_boundary" {
  source = "../../modules/permissions_boundary"

  name                  = local.boundary_name
  role_name_prefix      = "${var.project}-"
  protected_bucket_arns = [module.tfstate_bucket.arn]
}

# Interface for the daily layers (ADR-0019)
module "contract" {
  source = "../../modules/ssm_contract"

  path        = "/${var.project}/bootstrap"
  description = "Published by live/00_bootstrap"
  values = {
    permissions_boundary_arn     = module.permissions_boundary.arn
    ci_apply_role_arn            = module.gha_apply_role.arn
    gitops_deploy_key_secret_arn = aws_secretsmanager_secret.gitops_deploy_key.arn
  }
}

# Region-wide guard rails that protect every project in the account
module "account_baseline" {
  source = "../../modules/account_baseline"
}

# App CI role: GitHub Actions in eks-platform-app (main only) pushes images to ECR
module "gha_app_ci_role" {
  source = "../../modules/github_oidc_role"

  name              = local.app_ci_role_name
  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn
  subjects          = local.app_ci_role_subjects
  inline_policies = {
    ecr-push = data.aws_iam_policy_document.app_ci_ecr_push.json
  }
}
