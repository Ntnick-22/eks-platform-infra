# A guard-rail boundary: every role CI creates must carry it (enforced by the apply role's policy).
# Effective permissions = role's own policies ∩ this boundary, so whatever policy a role gets,
# it can never do what is denied here. Allow-all + targeted Denies is the usual boundary shape:
# it does not need updating for every new controller, only the dangerous actions are listed.

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "this" {
  statement {
    sid       = "AllowEverythingTheRolesOwnPolicyAllows"
    actions   = ["*"]
    resources = ["*"]
  }

  # Privilege escalation: creating identities or granting permissions.
  # Instance-profile actions stay allowed (Karpenter needs them later); PassRole is limited by each role's policy.
  statement {
    sid    = "DenyIamPrivilegeEscalation"
    effect = "Deny"
    actions = [
      "iam:CreateUser", "iam:CreateAccessKey", "iam:CreateLoginProfile", "iam:UpdateLoginProfile",
      "iam:CreateRole", "iam:UpdateAssumeRolePolicy", "iam:DeleteRolePermissionsBoundary", "iam:PutRolePermissionsBoundary",
      "iam:CreatePolicy", "iam:CreatePolicyVersion", "iam:SetDefaultPolicyVersion",
      "iam:AttachRolePolicy", "iam:AttachUserPolicy", "iam:AttachGroupPolicy",
      "iam:PutRolePolicy", "iam:PutUserPolicy", "iam:PutGroupPolicy", "iam:AddUserToGroup",
      "iam:CreateOpenIDConnectProvider", "iam:CreateSAMLProvider",
    ]
    resources = ["*"]
  }

  # A workload may hand only project roles to a service (e.g. Karpenter passes the node role to EC2)
  statement {
    sid           = "DenyPassingNonProjectRoles"
    effect        = "Deny"
    actions       = ["iam:PassRole"]
    not_resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.role_name_prefix}*"]
  }

  statement {
    sid       = "DenyAccountAndOrganization"
    effect    = "Deny"
    actions   = ["organizations:*", "account:*"]
    resources = ["*"]
  }

  # Audit trail must not be switched off from inside the platform
  statement {
    sid       = "DenyCloudTrailTampering"
    effect    = "Deny"
    actions   = ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail", "cloudtrail:UpdateTrail", "cloudtrail:PutEventSelectors"]
    resources = ["*"]
  }

  # Workloads never read or write Terraform state
  statement {
    sid       = "DenyProtectedBuckets"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = flatten([for b in var.protected_bucket_arns : [b, "${b}/*"]])
  }
}

resource "aws_iam_policy" "this" {
  name        = var.name
  description = "Permissions boundary for every role CI creates"
  policy      = data.aws_iam_policy_document.this.json
}
