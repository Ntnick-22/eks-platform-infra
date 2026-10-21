data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"

  # Skip Local Zones / Wavelength: only the region's normal AZs
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # "eu-west-1a" → "1a", used in names (myeks-private-app-1a) and as map keys
  az_keys = [for az in local.azs : regex("[0-9][a-z]$", az)]

  # Subnet plan for a /16 (ADR-0004). Index i = AZ number.
  #   public        /24  10.20.0.0,  10.20.1.0   ALB, NAT instance
  #   private-app   /20  10.20.16.0, 10.20.32.0  nodes + pods (VPC CNI gives pods VPC IPs, so these are big)
  #   private-data  /24  10.20.48.0, 10.20.49.0  RDS, no route to the internet
  # The data /24s start right after the last app /20 (one /20 = 16 /24s), so a 3rd AZ cannot overlap them.
  public_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  app_cidrs    = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 1)]
  data_cidrs   = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 16 * (var.az_count + 1) + i)]

  # Which AZs get a NAT instance, and which NAT each private-app route table uses.
  # single: everything → first AZ.  per_az: each AZ → its own.
  nat_keys   = var.nat_mode == "single" ? [local.az_keys[0]] : local.az_keys
  nat_for_az = { for k in local.az_keys : k => contains(local.nat_keys, k) ? k : local.nat_keys[0] }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = var.project
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets   = local.public_cidrs
  private_subnets  = local.app_cidrs
  database_subnets = local.data_cidrs

  public_subnet_names   = [for k in local.az_keys : "${var.project}-public-${k}"]
  private_subnet_names  = [for k in local.az_keys : "${var.project}-private-app-${k}"]
  database_subnet_names = [for k in local.az_keys : "${var.project}-private-data-${k}"]

  # Route table names: myeks-public, myeks-private-app-eu-west-1a, myeks-private-data-eu-west-1a
  private_subnet_suffix  = "private-app"
  database_subnet_suffix = "private-data"

  # No managed NAT gateway: outbound goes through our NAT instance below (ADR-0004).
  # single_nat_gateway = false (the default) also makes the module create ONE PRIVATE ROUTE TABLE PER AZ,
  # which is what lets nat_mode switch between single and per_az by changing only a route target.
  enable_nat_gateway = false

  # Without its own route table, the module associates database subnets with the PRIVATE route tables,
  # so they would inherit the NAT route. Own tables with no default route = data tier has no internet.
  create_database_subnet_route_table = true
  create_database_subnet_group       = false # 03_data creates the RDS subnet group it needs

  # Public subnets do not auto-assign public IPs: only the NAT instance and the ALB need one,
  # and both ask for it explicitly.
  map_public_ip_on_launch = false

  # Adopt the default security group and strip all its rules, so nothing can use it by accident.
  manage_default_security_group = true
  default_security_group_name   = "${var.project}-default-do-not-use"

  # AWS Load Balancer Controller finds subnets by these tags:
  # internet-facing ALB → public, internal ALB/NLB → private.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = var.cluster_name
  }
}

# ── NAT instance(s) ───────────────────────────────────────────────────────────
# Built from the open-source fck-nat AMI. ha_mode = an Auto Scaling group of exactly one instance:
# if the instance dies, the ASG launches a new one, which re-attaches the same static ENI,
# so the route below never has to change.

module "nat_instance" {
  source  = "RaJiska/fck-nat/aws"
  version = "1.6.1"

  for_each = toset(local.nat_keys)

  name          = "${var.project}-nat-${each.key}"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnets[index(local.az_keys, each.key)]
  instance_type = var.nat_instance_type

  ha_mode            = true
  use_spot_instances = false # a Spot interruption would cut all outbound traffic

  # Shell access through SSM Session Manager when debugging; no SSH key, no port 22.
  attach_ssm_policy = true

  permissions_boundary_arn = var.permissions_boundary_arn

  # We own the routes (below), so a nat_mode switch is an in-place route update,
  # not a delete in one module instance and a create in another racing for the same 0.0.0.0/0.
  update_route_tables = false
}

resource "aws_route" "private_app_default" {
  for_each = local.nat_for_az

  route_table_id         = module.vpc.private_route_table_ids[index(local.az_keys, each.key)]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.nat_instance[each.value].eni_id
}

# ── S3 gateway endpoint ───────────────────────────────────────────────────────
# Free. Image layers from ECR are stored in S3, so node pulls skip the NAT instance.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Name = "${var.project}-s3"
  }
}

# ── Interface endpoints (optional) ────────────────────────────────────────────
# One ENI per service per AZ in the private-app subnets. private_dns_enabled makes the normal
# hostname (e.g. sts.eu-west-1.amazonaws.com) resolve to those ENIs inside the VPC, so no client
# needs a config change: turning the toggle on or off only changes where the traffic goes.

resource "aws_security_group" "endpoints" {
  count = var.enable_interface_endpoints ? 1 : 0

  name        = "${var.project}-vpc-endpoints"
  description = "HTTPS from inside the VPC to interface endpoints"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.project}-vpc-endpoints"
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  count = var.enable_interface_endpoints ? 1 : 0

  security_group_id = aws_security_group.endpoints[0].id
  description       = "HTTPS from the VPC"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_interface_endpoints ? var.interface_endpoint_services : toset([])

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-${replace(each.key, ".", "-")}"
  }
}
