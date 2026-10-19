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
