# ── Required ──────────────────────────────────────────────────────────────────

variable "chart_version" {
  description = "argo-cd Helm chart version (Terraform owns upgrades: change it by PR)"
  type        = string
}

variable "apps_chart_version" {
  description = "argocd-apps Helm chart version (creates the root Application)"
  type        = string
}

variable "gitops_repo_url" {
  description = "HTTPS URL of the gitops repo the root Application syncs"
  type        = string

  validation {
    condition     = startswith(var.gitops_repo_url, "https://")
    error_message = "gitops_repo_url must be an https:// URL (public repo, no credentials)."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "namespace" {
  description = "Namespace Argo CD runs in"
  type        = string
  default     = "argocd"
}

variable "gitops_revision" {
  description = "Branch the root Application follows"
  type        = string
  default     = "main"
}

variable "root_path" {
  description = "Folder in the gitops repo the root Application syncs (Applications and ApplicationSets)"
  type        = string
  default     = "apps"
}
