region  = "eu-west-1"
project = "myeks"

# Upgrade by changing a version here in a PR: helm search repo <repo>/<chart> --versions
argocd_chart_version           = "10.10.5" # Argo CD v3.5.5
argocd_apps_chart_version      = "2.0.7"
external_secrets_chart_version = "2.13.0"
gitops_repo_url                = "git@github.com:Ntnick-22/eks-platform-gitops.git" # private: read-only deploy key
argocd_github_client_id        = "Ov23liShnyNtYiCv1TGR"                             # GitHub OAuth App myeks-argocd
argocd_admins                  = ["Ntnick-22"]
# Bump the policy file with the chart: policies/aws-load-balancer-controller.json is upstream's for this version
aws_load_balancer_controller_chart_version = "3.6.0"
external_dns_chart_version                 = "1.23.0"
