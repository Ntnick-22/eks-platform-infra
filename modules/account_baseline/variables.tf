# ── Optional ──────────────────────────────────────────────────────────────────

variable "ebs_encryption_by_default" {
  description = "Encrypt every new EBS volume in this region (nodes, NAT, PVCs), whatever tool creates it"
  type        = bool
  default     = true
}
