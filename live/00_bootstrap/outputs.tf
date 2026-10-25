output "tfstate_bucket_name" {
  description = "S3 bucket holding every layer's state (must match live/backend.hcl)"
  value       = module.tfstate_bucket.id
}

output "budget_name" {
  description = "Name of the account-wide monthly budget"
  value       = module.budget.name
}

output "gha_plan_role_arn" {
  description = "Role the plan workflow assumes (store as GitHub secret AWS_PLAN_ROLE_ARN)"
  value       = module.gha_plan_role.arn
}

output "ecr_repository_urls" {
  description = "Image repository URLs by app component (the app repo's CI pushes here)"
  value       = { for k, m in module.ecr : k => m.repository_url }
}

output "gha_apply_role_arn" {
  description = "Role the apply workflow assumes (store as secret AWS_APPLY_ROLE_ARN in the GitHub environment)"
  value       = module.gha_apply_role.arn
}

output "permissions_boundary_arn" {
  description = "Boundary every CI-created role must carry"
  value       = module.permissions_boundary.arn
}

output "gha_app_ci_role_arn" {
  description = "Role the app repo CI assumes (store as secret AWS_APP_CI_ROLE_ARN in eks-platform-app)"
  value       = module.gha_app_ci_role.arn
}

output "platform_certificate_arn" {
  description = "Wildcard certificate for <platform_domain> and *.<platform_domain> (the ALB controller discovers it by host)"
  value       = aws_acm_certificate_validation.platform.certificate_arn
}
