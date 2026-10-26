# External Secrets Operator. dev: in-cluster Password generator (postgres-dev credentials).
# prod: reads AWS (ClusterSecretStores in gitops) through its own Pod Identity role.
# Read-only, and only what the platform publishes for the apps: secrets under <project>/prod/
# (04_data writes the database credentials there) and the 04_data SSM contract (db_host).
data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid       = "ReadProdSecrets"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/prod/*"]
  }

  statement {
    sid       = "ReadDataContract"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/data/*"]
  }
}

module "external_secrets_role" {
  source = "../../modules/pod_identity_role"

  name                     = "${var.project}-external-secrets"
  permissions_boundary_arn = data.aws_ssm_parameter.permissions_boundary_arn.insecure_value
  inline_policy_json       = data.aws_iam_policy_document.external_secrets.json

  # Credentials are injected when a pod starts: the association must exist before ESO's pods
  association = {
    cluster_name    = data.aws_eks_cluster.this.name
    namespace       = "external-secrets"
    service_account = "external-secrets" # chart default: the release name
  }
}

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

  depends_on = [module.external_secrets_role]
}
