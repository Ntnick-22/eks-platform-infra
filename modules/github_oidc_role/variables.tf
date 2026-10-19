# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  description = "IAM role name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider (owned by the ECS project)"
  type        = string
}

variable "subjects" {
  description = "Exact GitHub OIDC 'sub' values allowed to assume this role"
  type        = list(string)

  validation {
    condition     = length(var.subjects) > 0
    error_message = "At least one subject is required."
  }

  validation {
    condition     = alltrue([for s in var.subjects : !strcontains(s, "*")])
    error_message = "Wildcards are not allowed in subjects - pin the exact repo and trigger."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach"
  type        = set(string)
  default     = []
}

variable "inline_policies" {
  description = "Inline policies: name => JSON policy document"
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Max session length in seconds (1-12 hours)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}
