# Loki (deployed by Argo CD, gitops apps/loki.yaml) stores logs in the persistent bucket from
# 00_bootstrap. Its own Pod Identity role: read/write that one bucket, nothing else.
data "aws_iam_policy_document" "loki" {
  statement {
    sid       = "ListLokiBucket"
    actions   = ["s3:ListBucket"]
    resources = [local.loki_bucket_arn]
  }

  statement {
    sid       = "ReadWriteLokiObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.loki_bucket_arn}/*"]
  }
}

locals {
  loki_bucket_arn = data.aws_ssm_parameter.loki_bucket_arn.insecure_value
}

# The association may exist before Argo CD creates the namespace and the service account:
# Loki's pods get the credentials whenever they start.
module "loki_role" {
  source = "../../modules/pod_identity_role"

  name                     = "${var.project}-loki"
  permissions_boundary_arn = data.aws_ssm_parameter.permissions_boundary_arn.insecure_value
  inline_policy_json       = data.aws_iam_policy_document.loki.json

  association = {
    cluster_name    = data.aws_eks_cluster.this.name
    namespace       = "monitoring"
    service_account = "loki" # the chart's default: the Argo CD app (= Helm release) name
  }
}
