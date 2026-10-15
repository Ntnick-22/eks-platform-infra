# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  description = "Budget name (unique in the account)"
  type        = string
}

variable "limit_usd" {
  description = "Monthly cost limit in USD"
  type        = number

  validation {
    condition     = var.limit_usd > 0
    error_message = "limit_usd must be greater than 0."
  }
}

variable "alert_emails" {
  description = "Email addresses that receive budget alerts"
  type        = list(string)
  sensitive   = true

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "At least one alert email is required."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "actual_thresholds" {
  description = "Alert when ACTUAL spend passes these percentages of the limit"
  type        = list(number)
  default     = [50, 80, 100]
}

variable "forecast_thresholds" {
  description = "Alert when FORECASTED spend passes these percentages of the limit"
  type        = list(number)
  default     = [100]
}
