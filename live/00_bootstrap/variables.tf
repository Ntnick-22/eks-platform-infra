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

variable "github_app_oidc_sub_prefix" {
  description = "App repo (eks-platform-app) OIDC sub prefix: gh api repos/<owner>/<repo>/actions/oidc/customization/sub"
  type        = string

  validation {
    condition     = startswith(var.github_app_oidc_sub_prefix, "repo:") && !strcontains(var.github_app_oidc_sub_prefix, "*")
    error_message = "github_app_oidc_sub_prefix must start with 'repo:' and contain no wildcard."
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

variable "github_apply_environment" {
  description = "Protected GitHub environment whose jobs may assume the apply role (main only, owner approval)"
  type        = string
}

variable "github_destroy_environment" {
  description = "GitHub environment for the nightly destroy (main only, no reviewer: nobody approves at 22:00)"
  type        = string
}

variable "ci_applied_layers" {
  description = "Layers CI applies, in order. The apply role may write only these state keys."
  type        = list(string)

  validation {
    condition     = !contains(var.ci_applied_layers, "00_bootstrap")
    error_message = "00_bootstrap is applied by a human only (ADR-0018): CI must never be able to change its own role."
  }
}

variable "hosted_zone_name" {
  description = "Existing public Route 53 zone (created outside Terraform, shared with other projects)"
  type        = string
}

variable "platform_domain" {
  description = "Subdomain the platform owns inside the zone: prod = <platform_domain>, dev = dev.<platform_domain>"
  type        = string

  validation {
    condition     = endswith(var.platform_domain, ".${var.hosted_zone_name}")
    error_message = "platform_domain must be a subdomain of hosted_zone_name."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "tfstate_noncurrent_version_days" {
  description = "Days to keep old versions of state files (recovery window)"
  type        = number
  default     = 90
}
