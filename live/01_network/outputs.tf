output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "private_app_subnet_ids" {
  description = "Private-app subnet IDs (EKS nodes and pods)"
  value       = module.network.private_app_subnet_ids
}

output "nat_for_az" {
  description = "Which NAT instance each private-app AZ routes through"
  value       = module.network.nat_for_az
}

output "contract_parameters" {
  description = "SSM parameters other layers read"
  value       = module.contract.parameter_names
}
