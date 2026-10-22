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

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version"
  type        = string
}

variable "argocd_apps_chart_version" {
  description = "argocd-apps Helm chart version (root Application)"
  type        = string
}

variable "gitops_repo_url" {
  description = "HTTPS URL of the gitops repo"
  type        = string
}
