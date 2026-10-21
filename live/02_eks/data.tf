data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ── Values owned by other layers (ADR-0019). insecure_value: these are IDs, not secrets,
# and .value would mark every subnet ID as sensitive in plans.

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/network/vpc_id"
}

data "aws_ssm_parameter" "private_app_subnet_ids" {
  name = "/${var.project}/network/private_app_subnet_ids"
}

data "aws_ssm_parameter" "permissions_boundary_arn" {
  name = "/${var.project}/bootstrap/permissions_boundary_arn"
}

data "aws_ssm_parameter" "ci_apply_role_arn" {
  name = "/${var.project}/bootstrap/ci_apply_role_arn"
}
