# Argo CD + the root Application; everything in the cluster after that comes from the gitops repo
module "argocd_bootstrap" {
  source = "../../modules/argocd_bootstrap"

  chart_version      = var.argocd_chart_version
  apps_chart_version = var.argocd_apps_chart_version
  gitops_repo_url    = var.gitops_repo_url
}
