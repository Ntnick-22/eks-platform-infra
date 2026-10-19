# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  description = "Repository name, e.g. \"$${var.project}/backend\""
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*$", var.name)) && length(var.name) <= 256
    error_message = "name must be lowercase letters, digits, '.', '_', '-' with optional '/' namespaces (max 256)."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "max_image_count" {
  description = "Images kept per repository (signatures and attestations included); older ones expire"
  type        = number
  default     = 30

  validation {
    condition     = var.max_image_count >= 1
    error_message = "max_image_count must be at least 1."
  }
}

variable "untagged_expire_days" {
  description = "Days before untagged images expire"
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_expire_days >= 1
    error_message = "untagged_expire_days must be at least 1."
  }
}

variable "kms_key_arn" {
  description = "KMS key for image encryption. null = AES256 (free)."
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Allow deleting the repository while it still has images. Keep false for anything important."
  type        = bool
  default     = false
}
