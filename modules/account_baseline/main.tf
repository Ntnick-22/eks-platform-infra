# Account/region-wide security settings that protect every project, not just this one.
# Persistent: lives in 00_bootstrap and is never part of the nightly destroy.

# Found 2026-10-21: the EBS CSI add-on's default StorageClass creates UNencrypted volumes.
# Encryption by default fixes that for every tool at once (CIS AWS benchmark). Uses the
# AWS-managed aws/ebs key (free). Only affects volumes created after it is enabled.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = var.ebs_encryption_by_default
}
