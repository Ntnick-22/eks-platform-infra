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
  description = "SSH URL of the private gitops repo (read with a deploy key); the root app syncs its apps/ folder"
  type        = string

  validation {
    condition     = startswith(var.gitops_repo_url, "git@github.com:")
    error_message = "gitops_repo_url must be an SSH URL (git@github.com:<owner>/<repo>.git): the deploy key only works over SSH."
  }
}

variable "argocd_github_client_id" {
  description = "Client ID of the GitHub OAuth App myeks-argocd (public; its secret is in Secrets Manager)"
  type        = string
}

variable "argocd_admins" {
  description = "GitHub logins with role:admin in Argo CD; every other GitHub user can log in but sees nothing"
  type        = list(string)

  validation {
    condition     = length(var.argocd_admins) > 0
    error_message = "argocd_admins needs at least one login: the local admin account is disabled."
  }
}

variable "external_secrets_chart_version" {
  description = "external-secrets Helm chart version"
  type        = string
}

variable "aws_load_balancer_controller_chart_version" {
  description = "aws-load-balancer-controller Helm chart version (policies/aws-load-balancer-controller.json must match it)"
  type        = string
}

variable "external_dns_chart_version" {
  description = "external-dns Helm chart version"
  type        = string
}
