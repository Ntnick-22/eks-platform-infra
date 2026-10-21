# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  description = "Policy name, e.g. \"myeks-boundary\""
  type        = string
}

variable "role_name_prefix" {
  description = "Only roles with this name prefix may be passed to services, e.g. \"myeks-\""
  type        = string
}

variable "protected_bucket_arns" {
  description = "Buckets no workload role may touch at all (e.g. the Terraform state bucket)"
  type        = list(string)
}
