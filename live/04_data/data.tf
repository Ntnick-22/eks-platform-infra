# Owned by other layers (ADR-0019). insecure_value: IDs, not secrets.
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/network/vpc_id"
}

data "aws_ssm_parameter" "private_data_subnet_ids" {
  name = "/${var.project}/network/private_data_subnet_ids"
}

data "aws_ssm_parameter" "azs" {
  name = "/${var.project}/network/azs"
}

# Pods use the node's security group (VPC CNI, no security groups per pod on our instance types)
data "aws_ssm_parameter" "node_security_group_id" {
  name = "/${var.project}/eks/node_security_group_id"
}
