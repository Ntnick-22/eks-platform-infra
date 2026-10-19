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

variable "name_prefix" {
  description = "Owner prefix for globally unique names (S3 buckets)"
  type        = string
}

variable "budget_limit_usd" {
  description = "Monthly account budget in USD"
  type        = number
}

variable "budget_alert_emails" {
  description = "Budget alert recipients. Set via TF_VAR_budget_alert_emails (laptop) or the BUDGET_ALERT_EMAILS GitHub secret (CI); never in tfvars."
  type        = list(string)
  sensitive   = true
}

variable "github_repo" {
  description = "GitHub repo (owner/name) whose workflows may use the CI roles"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "github_repo must look like owner/name."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "tfstate_noncurrent_version_days" {
  description = "Days to keep old versions of state files (recovery window)"
  type        = number
  default     = 90
}
