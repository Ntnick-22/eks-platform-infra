# ExternalDNS: creates the Route 53 records for Ingress hosts (dev.eks.<zone> → the ALB).
# The zone also holds other projects' records, so it is locked to <platform_domain> twice:
# by its own domain filter and by IAM (a bug or a wrong host still cannot touch anything else).
data "aws_iam_policy_document" "external_dns" {
  statement {
    sid       = "ChangeOnlyPlatformRecords"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:${data.aws_partition.current.partition}:route53:::hostedzone/${local.hosted_zone_id}"]

    # The owner TXT of a record is "<type>-<first label>…": for the apex itself (prod's host)
    # that is a-eks.<zone>, outside *.<platform_domain>, so those three names are listed exactly
    condition {
      test     = "ForAllValues:StringLike"
      variable = "route53:ChangeResourceRecordSetsNormalizedRecordNames"
      values = concat(
        [local.platform_domain, "*.${local.platform_domain}"],
        [for t in ["a", "aaaa", "cname"] : "${t}-${local.platform_domain}"],
      )
    }
  }

  statement {
    sid       = "ReadZones"
    actions   = ["route53:ListHostedZones", "route53:ListResourceRecordSets", "route53:ListTagsForResources"]
    resources = ["*"]
  }
}

module "external_dns_role" {
  source = "../../modules/pod_identity_role"

  name                     = "${var.project}-external-dns"
  permissions_boundary_arn = data.aws_ssm_parameter.permissions_boundary_arn.insecure_value
  inline_policy_json       = data.aws_iam_policy_document.external_dns.json

  association = {
    cluster_name    = data.aws_eks_cluster.this.name
    namespace       = local.external_dns_namespace
    service_account = "external-dns"
  }
}

locals {
  external_dns_namespace = "external-dns"
  hosted_zone_id         = data.aws_ssm_parameter.hosted_zone_id.insecure_value
  platform_domain        = data.aws_ssm_parameter.platform_domain.insecure_value
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = local.external_dns_namespace
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.external_dns_chart_version
  values = [
    file("${path.module}/helm-values/external-dns.yaml"),
    yamlencode({
      serviceAccount = { name = "external-dns" }
      domainFilters  = [local.platform_domain]
      # Owner tag in the TXT records: it only ever deletes records this cluster created
      txtOwnerId = var.project
      # zone-match-parent: the filter is a subdomain (eks.<zone>) of the zone; without it no zone
      # matches and ExternalDNS silently creates nothing ("record filter for domains: []")
      extraArgs = [
        "--zone-id-filter=${local.hosted_zone_id}",
        "--aws-zone-type=public",
        "--aws-zone-match-parent",
      ]
    }),
  ]
  wait    = true
  timeout = 600

  depends_on = [module.external_dns_role]
}
