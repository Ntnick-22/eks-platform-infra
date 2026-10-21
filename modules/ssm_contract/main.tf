# The contract is for non-secret IDs only (VPC ID, subnet IDs, ARNs): type is always String.
# Secrets live in Secrets Manager / Vault (CONVENTIONS.md §4), never here.

resource "aws_ssm_parameter" "this" {
  for_each = var.values

  name        = "${var.path}/${each.key}"
  description = var.description
  type        = "String"
  tier        = "Standard" # free; values are small IDs, far below the 4 KB limit

  # insecure_value instead of value: value is always marked sensitive, which would hide
  # every contract change in plan output. These are IDs, not secrets, so plans stay readable.
  insecure_value = each.value
}
