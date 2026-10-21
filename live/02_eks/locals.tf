locals {
  # One EKS cluster per project (ADR-0004)
  cluster_name = var.project

  contract_path = "/${var.project}/eks"

  # Contract lists are comma-joined, in AZ order (1a, 1b)
  private_app_subnet_ids = split(",", data.aws_ssm_parameter.private_app_subnet_ids.insecure_value)

  # Control plane ENIs in every AZ (EKS needs 2); nodes only in the first node_az_count AZs
  node_subnet_ids = slice(local.private_app_subnet_ids, 0, var.node_az_count)

  iam_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}"

  # Explicit cluster admins: you (laptop) + the CI apply role (bootstraps Argo CD in the next slice)
  admin_principal_arns = merge(
    { for u in var.cluster_admin_iam_users : "user-${u}" => "${local.iam_arn}:user/${u}" },
    { ci-apply = data.aws_ssm_parameter.ci_apply_role_arn.insecure_value },
  )
}
