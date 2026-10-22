# External Secrets Operator. Slice B: in-cluster Password generator only (dev DB credentials).
# Slice D adds its Pod Identity role + a ClusterSecretStore for AWS Secrets Manager (prod RDS).
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  values           = [file("${path.module}/helm-values/external-secrets.yaml")]
  wait             = true
  timeout          = 600
}
