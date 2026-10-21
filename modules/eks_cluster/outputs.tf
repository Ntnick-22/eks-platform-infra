output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster CA (base64), for providers and kubeconfig"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "Running Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group (control plane <-> nodes)"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Node security group: pods share it (no SG-per-pod on t-family), so RDS allows 5432 from it"
  value       = module.eks.node_security_group_id
}

output "node_iam_role_arn" {
  description = "Node role (Karpenter will reuse it)"
  value       = module.eks.eks_managed_node_groups["spot"].iam_role_arn
}

output "ebs_csi_role_arn" {
  description = "Pod Identity role of the EBS CSI driver"
  value       = module.ebs_csi_role.arn
}
