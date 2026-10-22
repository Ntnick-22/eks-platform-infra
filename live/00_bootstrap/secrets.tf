# Argo CD's read-only GitHub deploy key for the private gitops repo.
# Terraform creates only the empty container: the key goes in once by CLI
# (aws secretsmanager put-secret-value), so it never appears in code, plan output or state.
# 03_platform reads it at apply time through an ephemeral resource into a write-only Secret.
resource "aws_secretsmanager_secret" "gitops_deploy_key" {
  name                    = "${var.project}/argocd/gitops-deploy-key"
  description             = "SSH private key of the read-only deploy key on eks-platform-gitops (Argo CD)"
  recovery_window_in_days = 7
}
