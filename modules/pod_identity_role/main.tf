# Pod Identity: the EKS Pod Identity Agent on each node exchanges the pod's service account for
# credentials of this role. The trust is the same for every role (the pods.eks service); which
# pods may use it is decided by the association (cluster + namespace + service account), not here.
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.managed_policy_arns

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}

resource "aws_eks_pod_identity_association" "this" {
  count = var.association == null ? 0 : 1

  cluster_name    = var.association.cluster_name
  namespace       = var.association.namespace
  service_account = var.association.service_account
  role_arn        = aws_iam_role.this.arn
}
