# ── Required ──────────────────────────────────────────────────────────────────

variable "project" {
  description = "Project name, used as the prefix of every resource name (e.g. \"myeks\" → myeks-vpc, myeks-nat-1a)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, written to the karpenter.sh/discovery tag on the private-app subnets"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR. Must be a /16: every subnet CIDR is carved from it with cidrsubnet()"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr must be a valid IPv4 /16, e.g. 10.20.0.0/16."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "az_count" {
  description = "Number of AZs to spread subnets over (the first N AZs of the region)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 (EKS needs subnets in at least 2 AZs)."
  }
}

variable "nat_mode" {
  description = "\"single\" = one NAT instance in the first AZ for all private-app subnets; \"per_az\" = one NAT instance per AZ"
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_mode)
    error_message = "nat_mode must be \"single\" or \"per_az\"."
  }
}

variable "nat_instance_type" {
  description = "NAT instance type. A Graviton type (t4g.*) gets the arm64 AMI automatically"
  type        = string
  default     = "t4g.nano"
}

variable "enable_interface_endpoints" {
  description = "Create interface endpoints (PrivateLink) so AWS API calls skip the NAT. ~$0.01/h per service per AZ: demo days only"
  type        = bool
  default     = false
}

variable "interface_endpoint_services" {
  description = "AWS services that get an interface endpoint when enable_interface_endpoints = true"
  type        = set(string)
  default = [
    "ecr.api",              # image manifests, auth token
    "ecr.dkr",              # registry (layers themselves come from S3 via the gateway endpoint)
    "sts",                  # IRSA / role assumption
    "eks-auth",             # Pod Identity credentials
    "ec2",                  # VPC CNI, EBS CSI, Karpenter
    "elasticloadbalancing", # AWS Load Balancer Controller
    "logs",                 # CloudWatch Logs
    "kms",                  # Vault auto-unseal, EBS/S3 encryption calls
    "secretsmanager",       # External Secrets, Vault init
    "ssm",                  # SSM contract reads, Session Manager
    "ssmmessages",          # Session Manager shell
  ]
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary for the NAT instance role (required when CI applies: see ADR-0018)"
  type        = string
  default     = null
}
