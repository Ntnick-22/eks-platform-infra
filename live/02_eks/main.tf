module "eks_cluster" {
  source = "../../modules/eks_cluster"

  name               = local.cluster_name
  kubernetes_version = var.kubernetes_version
  addon_versions     = var.addon_versions

  vpc_id                   = data.aws_ssm_parameter.vpc_id.insecure_value
  control_plane_subnet_ids = local.private_app_subnet_ids
  node_subnet_ids          = local.node_subnet_ids

  admin_principal_arns     = local.admin_principal_arns
  permissions_boundary_arn = data.aws_ssm_parameter.permissions_boundary_arn.insecure_value

  node_instance_types     = var.node_instance_types
  node_min_size           = var.node_min_size
  node_max_size           = var.node_max_size
  node_desired_size       = var.node_desired_size
  control_plane_log_types = var.control_plane_log_types
}

# Interface for 03_data, 04_vault and CI scripts (ADR-0019)
module "contract" {
  source = "../../modules/ssm_contract"

  path        = local.contract_path
  description = "Published by live/02_eks"
  values = {
    cluster_name              = module.eks_cluster.cluster_name
    cluster_endpoint          = module.eks_cluster.cluster_endpoint
    cluster_version           = module.eks_cluster.cluster_version
    cluster_security_group_id = module.eks_cluster.cluster_security_group_id
    node_security_group_id    = module.eks_cluster.node_security_group_id
    node_iam_role_arn         = module.eks_cluster.node_iam_role_arn
  }
}
