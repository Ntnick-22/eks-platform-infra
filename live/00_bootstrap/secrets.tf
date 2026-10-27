# Argo CD's read-only GitHub deploy key for the private gitops repo.
# Terraform creates only the empty container: the key goes in once by CLI
# (aws secretsmanager put-secret-value), so it never appears in code, plan output or state.
# 03_platform reads it at apply time through an ephemeral resource into a write-only Secret.
resource "aws_secretsmanager_secret" "gitops_deploy_key" {
  name                    = "${var.project}/argocd/gitops-deploy-key"
  description             = "SSH private key of the read-only deploy key on eks-platform-gitops (Argo CD)"
  recovery_window_in_days = 7
}

# Client secret of the GitHub OAuth App "myeks-argocd" (Argo CD login via Dex). Same pattern:
# empty container, value put in once by CLI, read by 03_platform into a write-only Secret.
resource "aws_secretsmanager_secret" "argocd_github_oauth" {
  name                    = "${var.project}/argocd/github-oauth-client-secret"
  description             = "Client secret of the GitHub OAuth App myeks-argocd (Argo CD SSO via Dex)"
  recovery_window_in_days = 7
}

# Client secret of the GitHub OAuth App "myeks-grafana". Same pattern, but Grafana is deployed
# by Argo CD: External Secrets pulls it into the monitoring namespace (ESO may read
# <project>/monitoring/*, see 03_platform), so neither Terraform nor CI ever reads it.
resource "aws_secretsmanager_secret" "grafana_github_oauth" {
  name                    = "${var.project}/monitoring/grafana-github-oauth"
  description             = "Client secret of the GitHub OAuth App myeks-grafana (Grafana login)"
  recovery_window_in_days = 7
}
