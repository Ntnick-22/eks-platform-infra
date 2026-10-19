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

variable "github_oidc_sub_prefix" {
  description = "Repo's OIDC sub prefix (gh api repos/<owner>/<repo>/actions/oidc/customization/sub -> sub_claim_prefix)"
  type        = string

  validation {
    condition     = startswith(var.github_oidc_sub_prefix, "repo:") && !strcontains(var.github_oidc_sub_prefix, "*")
    error_message = "github_oidc_sub_prefix must start with 'repo:' and contain no wildcard."
  }
}

variable "ecr_repositories" {
  description = "App components that get an image repository (named <project>/<component>)"
  type        = list(string)

  validation {
    condition     = length(var.ecr_repositories) == length(distinct(var.ecr_repositories))
    error_message = "ecr_repositories must not contain duplicates."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "tfstate_noncurrent_version_days" {
  description = "Days to keep old versions of state files (recovery window)"
  type        = number
  default     = 90
}
