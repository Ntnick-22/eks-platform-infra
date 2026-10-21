# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  description = "IAM role name, e.g. \"myeks-ebs-csi\""
  type        = string
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary every CI-created role must carry"
  type        = string
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach"
  type        = set(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy (JSON) for permissions no managed policy covers"
  type        = string
  default     = null
}

variable "association" {
  description = "Pod Identity association to create. null = role only (e.g. an EKS add-on creates its own association)."
  type = object({
    cluster_name    = string
    namespace       = string
    service_account = string
  })
  default = null
}
