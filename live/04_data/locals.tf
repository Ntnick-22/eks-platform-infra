locals {
  identifier    = "${var.project}-prod"
  contract_path = "/${var.project}/data"

  # Same AZ as the nodes (node_az_count = 1 → first AZ): no cross-AZ traffic charges
  availability_zone = split(",", data.aws_ssm_parameter.azs.insecure_value)[0]

  # Fixed name: gitops points ESO at it. The RDS-managed secret is named rds!db-<id>,
  # and that id changes on every restore.
  secret_name = "${var.project}/prod/db"
}
