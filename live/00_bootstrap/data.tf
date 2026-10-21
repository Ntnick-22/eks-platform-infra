# Created by the ECS project (aws_ecs_infra). Look it up here, never create a second one.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Managed-policy ARNs are built from the partition: data "aws_iam_policy" would download
# the whole ReadOnlyAccess document, which is too large for the provider to parse.
data "aws_partition" "current" {}

# ReadOnlyAccess can read state, but plan also takes a lock:
# it writes <key>.tflock next to the state file and deletes it afterwards.
data "aws_iam_policy_document" "tfstate_lock" {
  statement {
    sid       = "TerraformStateLockFile"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.tfstate_bucket.arn}/*.tflock"]
  }
}

data "aws_caller_identity" "current" {}

# ── Apply role permissions: what layers in ci_applied_layers need, nothing more ──
# Grow this policy in the same PR that adds a layer to ci_applied_layers.
data "aws_iam_policy_document" "ci_apply" {
  # 01_network: VPC, subnets, routes, endpoints, security groups, NAT instance (launch template + ASG).
  # Whole services, but only in our region: per-action EC2 lists are long and break on every new resource.
  statement {
    sid       = "Ec2AndAutoscalingInRegion"
    actions   = ["ec2:*", "autoscaling:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # IAM only for resources named <project>-* (e.g. the NAT instance role myeks-nat-1a)
  statement {
    sid = "IamProjectRolesAndProfiles"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole", "iam:UpdateAssumeRolePolicy",
      "iam:TagRole", "iam:UntagRole",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile", "iam:UntagInstanceProfile",
    ]
    resources = [
      "${local.iam_arn}:role/${var.project}-*",
      "${local.iam_arn}:instance-profile/${var.project}-*",
    ]
  }

  statement {
    sid = "IamProjectPolicies"
    actions = [
      "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy", "iam:TagPolicy", "iam:UntagPolicy",
      "iam:CreatePolicyVersion", "iam:DeletePolicyVersion", "iam:GetPolicyVersion", "iam:ListPolicyVersions",
    ]
    resources = ["${local.iam_arn}:policy/${var.project}-*"]
  }

  # Attach only our own customer policies: never AdministratorAccess or any other AWS-managed policy
  statement {
    sid       = "IamAttachOnlyProjectPolicies"
    actions   = ["iam:AttachRolePolicy", "iam:DetachRolePolicy"]
    resources = ["${local.iam_arn}:role/${var.project}-*"]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values   = ["${local.iam_arn}:policy/${var.project}-*"]
    }
  }

  # The NAT instance's ASG launches EC2 with a project instance profile
  statement {
    sid       = "PassProjectRolesToEc2"
    actions   = ["iam:PassRole"]
    resources = ["${local.iam_arn}:role/${var.project}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # First ASG in an account creates this AWS role; it already exists here, but a fresh account needs it
  statement {
    sid       = "AutoscalingServiceLinkedRole"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["${local.iam_arn}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["autoscaling.amazonaws.com"]
    }
  }

  # SSM contract: /<project>/* only
  statement {
    sid = "SsmContract"
    actions = [
      "ssm:PutParameter", "ssm:DeleteParameter", "ssm:DeleteParameters",
      "ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath",
      "ssm:AddTagsToResource", "ssm:RemoveTagsFromResource", "ssm:ListTagsForResource",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.region}:${local.account_id}:parameter/${var.project}/*"]
  }

  # State: write only the keys of the layers CI applies (state file + lockfile). 00_bootstrap stays read-only.
  statement {
    sid       = "TerraformStateCiLayers"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for l in var.ci_applied_layers : "${module.tfstate_bucket.arn}/${l}/*"]
  }

  # Guard rail: myeks-* also matches the CI roles themselves. Without this, the apply role could
  # rewrite its own trust/policies (or the plan role's) and grant itself anything.
  statement {
    sid       = "DenyChangingCiRoles"
    effect    = "Deny"
    actions   = ["iam:*"]
    resources = ["${local.iam_arn}:role/${var.project}-gha-*"]
  }
}
