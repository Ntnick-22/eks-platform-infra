region  = "eu-west-1"
project = "myeks"

# Upgrade Argo CD by changing this in a PR: helm search repo argo/argo-cd --versions
argocd_chart_version      = "10.10.5" # Argo CD v3.5.5
argocd_apps_chart_version = "2.0.7"
gitops_repo_url           = "https://github.com/Ntnick-22/eks-platform-gitops.git"
