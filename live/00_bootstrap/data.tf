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
  # 01_network: VPC, subnets, routes, endpoints, SGs, NAT instance (launch template + ASG).
  # 02_eks: cluster, node group, add-ons, access entries, Pod Identity associations.
  # Whole services, but only in our region: per-action lists are long and break on every new resource.
  statement {
    sid       = "RegionalServicesInRegion"
    actions   = ["ec2:*", "autoscaling:*", "eks:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # EKS control plane logs (drill days only): /aws/eks/<cluster>/cluster
  statement {
    sid       = "EksControlPlaneLogGroup"
    actions   = ["logs:*"]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.region}:${local.account_id}:log-group:/aws/eks/${var.project}/*"]
  }

  # ── IAM: only <project>-* roles, and only with the boundary attached ──
  statement {
    sid       = "IamCreateRoleOnlyWithBoundary"
    actions   = ["iam:CreateRole", "iam:PutRolePermissionsBoundary"]
    resources = ["${local.iam_arn}:role/${var.project}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [module.permissions_boundary.arn]
    }
  }

  statement {
    sid = "IamProjectRolesAndProfiles"
    actions = [
      "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole", "iam:UpdateAssumeRolePolicy",
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

  # Attach only our own policies or the short list of AWS-managed ones EKS needs: never AdministratorAccess
  statement {
    sid       = "IamAttachAllowListedPolicies"
    actions   = ["iam:AttachRolePolicy", "iam:DetachRolePolicy"]
    resources = ["${local.iam_arn}:role/${var.project}-*"]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values = concat(
        ["${local.iam_arn}:policy/${var.project}-*"],
        [for p in local.attachable_aws_policies : "arn:${data.aws_partition.current.partition}:iam::aws:policy/${p}"],
      )
    }
  }

  # NAT instance → EC2, cluster + node group → EKS, Pod Identity → pods.eks
  statement {
    sid       = "PassProjectRolesToServices"
    actions   = ["iam:PassRole"]
    resources = ["${local.iam_arn}:role/${var.project}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "eks.amazonaws.com", "pods.eks.amazonaws.com"]
    }
  }

  # These already exist in this account; a fresh account creates them on first use
  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["${local.iam_arn}:role/aws-service-role/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = local.service_linked_role_services
    }
  }

  # 03_platform: Argo CD's gitops deploy key, read at apply time into a write-only Secret (never in state).
  # ReadOnlyAccess does not include GetSecretValue, so the plan role can never read it.
  statement {
    sid       = "ReadGitopsDeployKey"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.gitops_deploy_key.arn]
  }

  # ── SSM contract: read every layer, write only the CI layers' own paths ──
  statement {
    sid       = "SsmContractRead"
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath", "ssm:ListTagsForResource"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.region}:${local.account_id}:parameter/${var.project}/*"]
  }

  statement {
    sid = "SsmContractWriteOwnLayers"
    actions = [
      "ssm:PutParameter", "ssm:DeleteParameter", "ssm:DeleteParameters",
      "ssm:AddTagsToResource", "ssm:RemoveTagsFromResource",
    ]
    resources = [for p in local.ci_contract_paths : "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${local.account_id}:parameter/${var.project}/${p}/*"]
  }

  # State: write only the keys of the layers CI applies (state file + lockfile). 00_bootstrap stays read-only.
  statement {
    sid       = "TerraformStateCiLayers"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for l in var.ci_applied_layers : "${module.tfstate_bucket.arn}/${l}/*"]
  }

  # ── Guard rails (explicit Deny always wins) ──
  # myeks-* also matches the CI roles: without this the apply role could rewrite its own trust or policies.
  # Reads stay allowed: the EKS module resolves "who am I" with iam:GetRole on the caller's own role.
  statement {
    sid         = "DenyChangingCiRoles"
    effect      = "Deny"
    not_actions = ["iam:Get*", "iam:List*"]
    resources   = ["${local.iam_arn}:role/${var.project}-gha-*"]
  }

  # myeks-* also matches the boundary itself: CI must not weaken it or strip it from a role
  statement {
    sid         = "DenyChangingBoundary"
    effect      = "Deny"
    not_actions = ["iam:Get*", "iam:List*"]
    resources   = [module.permissions_boundary.arn]
  }

  statement {
    sid       = "DenyRemovingBoundaryFromRoles"
    effect    = "Deny"
    actions   = ["iam:DeleteRolePermissionsBoundary"]
    resources = ["*"]
  }
}

# ── App CI: push images to our ECR repositories, nothing else ──
# GetAuthorizationToken has no resource-level permissions (it only returns a registry login).
data "aws_iam_policy_document" "app_ci_ecr_push" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPushOwnRepositories"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
    ]
    resources = [for m in module.ecr : m.arn]
  }
}
