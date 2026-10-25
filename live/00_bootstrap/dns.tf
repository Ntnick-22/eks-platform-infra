# Public DNS + TLS for everything the platform serves (eks.<zone> = prod, dev.eks.<zone>, later
# argocd./grafana.). Persistent on purpose: a certificate is free, but DNS validation takes minutes
# and the validation records must stay, so it is not rebuilt every day with the cluster.
# The zone itself was created by hand long ago and hosts other projects: look it up, never manage it.
data "aws_route53_zone" "root" {
  name         = var.hosted_zone_name
  private_zone = false
}

# One wildcard certificate for the whole platform. The ALB controller finds it by host name
# (certificate discovery), so no ARN (and no account ID) is ever written into the gitops repo.
resource "aws_acm_certificate" "platform" {
  domain_name               = var.platform_domain
  subject_alternative_names = ["*.${var.platform_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true # a replacement is issued before the old one is removed
  }
}

# eks.<zone> and *.eks.<zone> share one validation record: dedupe by record name
resource "aws_route53_record" "platform_cert_validation" {
  for_each = {
    for o in aws_acm_certificate.platform.domain_validation_options : o.resource_record_name => o...
  }

  zone_id = data.aws_route53_zone.root.zone_id
  name    = each.key
  type    = each.value[0].resource_record_type
  records = [each.value[0].resource_record_value]
  ttl     = 300
}

# Waits until ACM has issued the certificate (usually 1-5 minutes)
resource "aws_acm_certificate_validation" "platform" {
  certificate_arn         = aws_acm_certificate.platform.arn
  validation_record_fqdns = [for r in aws_route53_record.platform_cert_validation : r.fqdn]
}
