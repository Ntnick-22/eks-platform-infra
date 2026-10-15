# ── Required ──────────────────────────────────────────────────────────────────

variable "bucket_name" {
  description = "Globally unique bucket name, e.g. \"$${var.name_prefix}-tfstate\""
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 chars: lowercase letters, digits, dots and hyphens."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "versioning_enabled" {
  description = "Keep old object versions (needed for tfstate recovery; usually off for log/chunk buckets). Once enabled, it can only be suspended."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key for SSE-KMS. null = SSE-S3 (AES256, free)."
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Delete old (noncurrent) object versions after N days. null = keep forever."
  type        = number
  default     = null

  validation {
    condition     = var.noncurrent_version_expiration_days == null ? true : var.noncurrent_version_expiration_days > 0
    error_message = "noncurrent_version_expiration_days must be > 0 or null."
  }
}

variable "expiration_days" {
  description = "Delete current objects after N days (e.g. Loki chunks). null = never."
  type        = number
  default     = null

  validation {
    condition     = var.expiration_days == null ? true : var.expiration_days > 0
    error_message = "expiration_days must be > 0 or null."
  }
}

variable "force_destroy" {
  description = "Allow destroying the bucket while it still has objects. Keep false for anything important."
  type        = bool
  default     = false
}
