# Alertmanager (kube-prometheus-stack, gitops apps/monitoring.yaml) sends alerts to the
# persistent SNS topic from 00_bootstrap. Its own Pod Identity role: publish to that topic only.
data "aws_iam_policy_document" "alertmanager" {
  statement {
    sid       = "PublishPlatformAlerts"
    actions   = ["sns:Publish"]
    resources = [data.aws_ssm_parameter.alerts_topic_arn.insecure_value]
  }
}

module "alertmanager_role" {
  source = "../../modules/pod_identity_role"

  name                     = "${var.project}-alertmanager"
  permissions_boundary_arn = data.aws_ssm_parameter.permissions_boundary_arn.insecure_value
  inline_policy_json       = data.aws_iam_policy_document.alertmanager.json

  association = {
    cluster_name    = data.aws_eks_cluster.this.name
    namespace       = "monitoring"
    service_account = "alertmanager" # set explicitly in apps/monitoring.yaml
  }
}
