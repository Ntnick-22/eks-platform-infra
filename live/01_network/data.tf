# Values owned by 00_bootstrap (ADR-0019)
data "aws_ssm_parameter" "permissions_boundary_arn" {
  name = "/${var.project}/bootstrap/permissions_boundary_arn"
}
