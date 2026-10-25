# AWS Load Balancer Controller: turns Ingresses into one shared ALB (IngressGroup), TLS from the
# ACM wildcard certificate of 00_bootstrap (found by host name). Terraform owns it because it needs
# an AWS role (ADR: add-on split). Its pods get AWS credentials through Pod Identity.
module "alb_controller_role" {
  source = "../../modules/pod_identity_role"

  name                     = "${var.project}-alb-controller"
  permissions_boundary_arn = data.aws_ssm_parameter.permissions_boundary_arn.insecure_value
  # Upstream policy of the pinned controller version, unchanged (docs/install/iam_policy.json).
  # Update it together with the chart version.
  inline_policy_json = file("${path.module}/policies/aws-load-balancer-controller.json")

  association = {
    cluster_name    = data.aws_eks_cluster.this.name
    namespace       = "kube-system"
    service_account = local.alb_controller_service_account
  }
}

locals {
  alb_controller_service_account = "aws-load-balancer-controller"
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_load_balancer_controller_chart_version
  values = [
    file("${path.module}/helm-values/aws-load-balancer-controller.yaml"),
    # Set explicitly: the nodes allow one IMDS hop, so the pods cannot look these up themselves
    yamlencode({
      clusterName    = data.aws_eks_cluster.this.name
      region         = var.region
      vpcId          = data.aws_ssm_parameter.vpc_id.insecure_value
      serviceAccount = { name = local.alb_controller_service_account }
    }),
  ]
  wait    = true
  timeout = 600

  # Credentials must exist before the first pod starts
  depends_on = [module.alb_controller_role]
}
