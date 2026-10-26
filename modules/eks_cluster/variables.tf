# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  description = "Cluster name; also the prefix of its IAM roles and security groups (e.g. \"myeks\")"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version (minor), e.g. \"1.36\". Stay in STANDARD support: extended support is 6x the price."
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must look like \"1.36\"."
  }
}

variable "vpc_id" {
  description = "VPC ID (from the 01_network contract)"
  type        = string
}

variable "control_plane_subnet_ids" {
  description = "Subnets for the control plane's ENIs: at least 2 AZs (EKS requirement)"
  type        = list(string)

  validation {
    condition     = length(var.control_plane_subnet_ids) >= 2
    error_message = "EKS needs control plane subnets in at least 2 AZs."
  }
}

variable "node_subnet_ids" {
  description = "Subnets for worker nodes. One AZ by default: EBS volumes cannot follow a pod to another AZ."
  type        = list(string)
}

variable "admin_principal_arns" {
  description = "IAM principals that get cluster-admin through an access entry, keyed by a short label"
  type        = map(string)
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary for every role this module creates (cluster, nodes, Pod Identity)"
  type        = string
}

variable "addon_versions" {
  description = "Exact EKS add-on versions (aws eks describe-addon-versions). Pinned: without a version the module installs the most recent one, so add-ons changed on any apply."
  type        = map(string)

  validation {
    condition = alltrue([for a in ["vpc-cni", "eks-pod-identity-agent", "kube-proxy", "coredns", "metrics-server", "aws-ebs-csi-driver"] :
    contains(keys(var.addon_versions), a)])
    error_message = "addon_versions needs a version for every add-on: vpc-cni, eks-pod-identity-agent, kube-proxy, coredns, metrics-server, aws-ebs-csi-driver."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "node_instance_types" {
  description = "Spot instance types: several types = fewer \"no Spot capacity\" failures. Graviton (arm64) only."
  type        = list(string)
  default     = ["t4g.large", "m6g.large", "m7g.large"]
}

variable "node_min_size" {
  description = "Minimum nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Nodes at creation (later changes are ignored: the autoscaler owns this number)"
  type        = number
  default     = 2
}

variable "node_disk_size_gb" {
  description = "Root volume per node (gp3, encrypted)"
  type        = number
  default     = 20
}

variable "endpoint_public_access_cidrs" {
  description = "Who may reach the public API endpoint (still IAM-authenticated). GitHub runner IPs vary, so open for now."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "control_plane_log_types" {
  description = "Control plane logs to CloudWatch. [] daily; [\"audit\", \"authenticator\"] on drill days."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for t in var.control_plane_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)])
    error_message = "Allowed: api, audit, authenticator, controllerManager, scheduler."
  }
}
