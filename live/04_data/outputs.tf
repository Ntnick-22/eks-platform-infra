output "db_endpoint" {
  description = "Prod database host:port (private: reachable from the cluster only)"
  value       = aws_db_instance.prod.endpoint
}

output "restored_from" {
  description = "Snapshot this database was restored from (null = created empty)"
  value       = var.restore_snapshot_identifier
}
