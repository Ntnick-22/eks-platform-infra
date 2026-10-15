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
