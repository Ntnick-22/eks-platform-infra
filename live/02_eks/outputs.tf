output "cluster_name" {
  description = "Cluster name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_version" {
  description = "Running Kubernetes version"
  value       = module.eks_cluster.cluster_version
}

output "kubeconfig_command" {
  description = "Run this to point kubectl / k9s at the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks_cluster.cluster_name}"
}

output "contract_parameters" {
  description = "SSM parameters other layers read"
  value       = module.contract.parameter_names
}
