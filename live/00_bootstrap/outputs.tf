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
