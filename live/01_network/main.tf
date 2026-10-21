module "network" {
  source = "../../modules/network"

  project                    = var.project
  cluster_name               = local.cluster_name
  vpc_cidr                   = var.vpc_cidr
  az_count                   = var.az_count
  nat_mode                   = var.nat_mode
  nat_instance_type          = var.nat_instance_type
  enable_interface_endpoints = var.enable_interface_endpoints
}

# Interface for 02_eks and 03_data (ADR-0019). Lists are comma-joined: SSM String holds one value.
module "contract" {
  source = "../../modules/ssm_contract"

  path        = local.contract_path
  description = "Published by live/01_network"
  values = {
    vpc_id                  = module.network.vpc_id
    vpc_cidr_block          = module.network.vpc_cidr_block
    azs                     = join(",", module.network.azs)
    public_subnet_ids       = join(",", module.network.public_subnet_ids)
    private_app_subnet_ids  = join(",", module.network.private_app_subnet_ids)
    private_data_subnet_ids = join(",", module.network.private_data_subnet_ids)
  }
}
