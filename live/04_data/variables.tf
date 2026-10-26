# ── Required ──────────────────────────────────────────────────────────────────

variable "region" {
  description = "AWS region for this layer"
  type        = string
}

variable "project" {
  description = "Short project name used in resource names and the Project tag"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "project must be lowercase letters, digits and hyphens (2-21 chars)."
  }
}

variable "postgres_version" {
  description = "Exact PostgreSQL version (same major as postgres-dev and the backend CI)"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage_gb" {
  description = "Disk size in GB (gp3)"
  type        = number
}

variable "db_name" {
  description = "Database the backend uses (POSTGRES_DB)"
  type        = string
}

variable "master_username" {
  description = "Master user the backend connects as (until Vault issues per-pod users, slice F)"
  type        = string
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "restore_snapshot_identifier" {
  description = "Snapshot to restore from (newest myeks-prod-*, found by scripts/latest-db-snapshot.sh). null = new empty database."
  type        = string
  default     = null
}

variable "password_version" {
  description = "Bump to set a new master password (write-only: Terraform cannot see a change otherwise)"
  type        = number
  default     = 1
}
