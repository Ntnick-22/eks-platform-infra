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

variable "kubernetes_version" {
  description = "EKS Kubernetes version; CI warns when its standard support ends within 90 days"
  type        = string
}

variable "cluster_admin_iam_users" {
  description = "IAM user names (this account) that get cluster-admin, e.g. the laptop user running kubectl/k9s"
  type        = list(string)
}

variable "addon_versions" {
  description = "Exact EKS add-on versions, bumped by PR (aws eks describe-addon-versions --kubernetes-version <v> --addon-name <name>)"
  type        = map(string)
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "node_az_count" {
  description = "How many AZs the nodes use: 1 daily (EBS is per AZ), 2 for spread/AZ-failure drills"
  type        = number
  default     = 1
}

variable "node_instance_types" {
  description = "Spot instance types (Graviton)"
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
  description = "Nodes at creation"
  type        = number
  default     = 2
}

variable "control_plane_log_types" {
  description = "Control plane logs: [] daily, [\"audit\", \"authenticator\"] on drill days"
  type        = list(string)
  default     = []
}
