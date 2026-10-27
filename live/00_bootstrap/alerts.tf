# Platform alerts: Alertmanager (gitops apps/monitoring.yaml) → this topic → email.
# Persistent, so the email subscription is confirmed once (AWS sends a confirmation link)
# and survives the nightly destroy. Same recipients as the budget alerts.
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

# count, not for_each: the address list is sensitive, and for_each would print its keys.
resource "aws_sns_topic_subscription" "alerts_email" {
  count = nonsensitive(length(var.budget_alert_emails))

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.budget_alert_emails[count.index]
}
