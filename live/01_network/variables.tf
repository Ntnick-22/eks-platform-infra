# ── Required ──────────────────────────────────────────────────────────────────

variable "region" {
  description = "AWS region for this layer"
  type        = string
}

variable "project" {
  description = "Short project name used in resource names and the Project tag"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "project must be lowercase letters, digits and hyphens (2-21 chars)."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR (/16); every subnet is carved from it"
  type        = string
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "az_count" {
  description = "Number of AZs (2 normally, 3 for drills)"
  type        = number
  default     = 2
}

variable "nat_mode" {
  description = "\"single\" (daily) or \"per_az\" (AZ-failure drills)"
  type        = string
  default     = "single"
}

variable "nat_instance_type" {
  description = "NAT instance type"
  type        = string
  default     = "t4g.nano"
}

variable "enable_interface_endpoints" {
  description = "Interface endpoints for AWS APIs (~$0.22/h for 11 services x 2 AZs): demo days only"
  type        = bool
  default     = false
}
