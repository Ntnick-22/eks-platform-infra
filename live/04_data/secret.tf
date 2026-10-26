# Credentials for the prod backend, read by External Secrets (gitops: ExternalSecret backend-db).
# The password is written here and into RDS from the same ephemeral value, both write-only:
# it is in Secrets Manager only, never in Terraform state, plan output or git.
resource "aws_secretsmanager_secret" "db" {
  name        = local.secret_name
  description = "Prod database credentials for the backend (synced into Kubernetes by External Secrets)"
  # Re-created every day under the same name: delete at once instead of a 7-30 day recovery window
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  # Key names = the env vars app.py reads, so the ExternalSecret can map them 1:1
  secret_string_wo = jsonencode({
    POSTGRES_DB       = var.db_name
    POSTGRES_USER     = var.master_username
    POSTGRES_PASSWORD = ephemeral.random_password.db.result
  })
  secret_string_wo_version = var.password_version

  # The secret must only be readable once the database accepts this password
  depends_on = [aws_db_instance.prod]
}
