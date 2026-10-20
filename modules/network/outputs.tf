output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR (for security group rules that allow traffic from inside the VPC)"
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "AZ names used, in subnet order"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnet IDs, one per AZ (ALB, NAT instance)"
  value       = module.vpc.public_subnets
}

output "private_app_subnet_ids" {
  description = "Private-app subnet IDs, one per AZ (EKS nodes and pods)"
  value       = module.vpc.private_subnets
}

output "private_data_subnet_ids" {
  description = "Private-data subnet IDs, one per AZ (RDS); no internet route"
  value       = module.vpc.database_subnets
}

output "private_app_route_table_ids" {
  description = "Private-app route table IDs, one per AZ"
  value       = module.vpc.private_route_table_ids
}

output "nat_instance_eni_ids" {
  description = "Static ENI of each NAT instance, keyed by short AZ (\"1a\")"
  value       = { for k, m in module.nat_instance : k => m.eni_id }
}

output "interface_endpoint_ids" {
  description = "Interface endpoint IDs keyed by service (empty when enable_interface_endpoints = false)"
  value       = { for k, e in aws_vpc_endpoint.interface : k => e.id }
}

output "nat_for_az" {
  description = "Which NAT instance each private-app AZ routes through, e.g. { \"1a\" = \"1a\", \"1b\" = \"1a\" }"
  value       = local.nat_for_az
}
