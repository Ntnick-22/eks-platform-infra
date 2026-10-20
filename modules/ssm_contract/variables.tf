# ── Required ──────────────────────────────────────────────────────────────────

variable "path" {
  description = "Parameter path prefix owned by the publishing layer, e.g. \"/myeks/network\""
  type        = string

  validation {
    condition     = can(regex("^(/[a-z0-9_-]+)+$", var.path))
    error_message = "path must start with '/', have no trailing '/', and use lowercase letters, digits, '_' or '-' (e.g. /myeks/network)."
  }
}

variable "values" {
  description = "Parameter name (under path) → value. Lists must be joined into one string first, e.g. join(\",\", ids). Never secrets."
  type        = map(string)

  validation {
    condition     = alltrue([for k in keys(var.values) : can(regex("^[a-z0-9_]+$", k))])
    error_message = "values keys must be lowercase snake_case (e.g. private_app_subnet_ids)."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "description" {
  description = "Description written on every parameter, so the console shows who owns it"
  type        = string
  default     = "Published by Terraform (SSM contract)"
}
