# Cluster name from the 02_eks contract (ADR-0019); endpoint + CA from EKS itself
data "aws_ssm_parameter" "cluster_name" {
  name = "/${var.project}/eks/cluster_name"
}

data "aws_eks_cluster" "this" {
  name = data.aws_ssm_parameter.cluster_name.insecure_value
}
