# Cluster name from the 02_eks contract (ADR-0019); endpoint + CA from EKS itself
data "aws_ssm_parameter" "cluster_name" {
  name = "/${var.project}/eks/cluster_name"
}

data "aws_eks_cluster" "this" {
  name = data.aws_ssm_parameter.cluster_name.insecure_value
}

# Secrets Manager container for Argo CD's gitops deploy key (created empty by 00_bootstrap)
data "aws_ssm_parameter" "gitops_deploy_key_secret_arn" {
  name = "/${var.project}/bootstrap/gitops_deploy_key_secret_arn"
}

# Same for the GitHub OAuth client secret (Argo CD login)
data "aws_ssm_parameter" "argocd_github_oauth_secret_arn" {
  name = "/${var.project}/bootstrap/argocd_github_oauth_secret_arn"
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

# Owned by other layers (ADR-0019). insecure_value: IDs and names, not secrets.
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/network/vpc_id"
}

data "aws_ssm_parameter" "permissions_boundary_arn" {
  name = "/${var.project}/bootstrap/permissions_boundary_arn"
}

# Public zone + platform domain (the ACM certificate for it lives in 00_bootstrap too)
data "aws_ssm_parameter" "hosted_zone_id" {
  name = "/${var.project}/bootstrap/hosted_zone_id"
}

data "aws_ssm_parameter" "platform_domain" {
  name = "/${var.project}/bootstrap/platform_domain"
}
