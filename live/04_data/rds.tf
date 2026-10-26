# Prod database: RDS PostgreSQL, rebuilt every day with the rest of the stack. Data survives
# the nightly teardown through snapshots: the destroy workflow takes a dated snapshot
# (myeks-prod-YYYYMMDD-HHMM) and the next apply restores the newest one (ADR: snapshot + restore).
resource "aws_db_subnet_group" "prod" {
  name        = local.identifier
  description = "Private data subnets (no route to the internet)"
  subnet_ids  = split(",", data.aws_ssm_parameter.private_data_subnet_ids.insecure_value)
}

resource "aws_security_group" "db" {
  name        = "${local.identifier}-db"
  description = "Postgres from the EKS nodes only"
  vpc_id      = data.aws_ssm_parameter.vpc_id.insecure_value

  tags = { Name = "${local.identifier}-db" }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_nodes" {
  security_group_id            = aws_security_group.db.id
  description                  = "Postgres from pods (they use the node security group)"
  referenced_security_group_id = data.aws_ssm_parameter.node_security_group_id.insecure_value
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# New password on every create (and on password_version bumps). Ephemeral: it exists only
# during the run and goes write-only into RDS and Secrets Manager, never into state or plans.
ephemeral "random_password" "db" {
  length           = 32
  override_special = "!#%*-_=+" # no quotes, @, / or spaces: they break connection strings
}

resource "aws_db_instance" "prod" {
  identifier     = local.identifier
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.instance_class

  # Ignored by AWS when restoring: the snapshot brings its own database and master user
  db_name             = var.db_name
  username            = var.master_username
  password_wo         = ephemeral.random_password.db.result
  password_wo_version = var.password_version

  snapshot_identifier = var.restore_snapshot_identifier

  allocated_storage = var.allocated_storage_gb
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.prod.name
  vpc_security_group_ids = [aws_security_group.db.id]
  availability_zone      = local.availability_zone
  multi_az               = false # dev-budget prod: a restart means a few minutes of downtime
  publicly_accessible    = false

  # Upgrades only through a PR that changes postgres_version
  auto_minor_version_upgrade = false
  apply_immediately          = true

  # 1 day of automated backups (free up to the DB size) for point-in-time restore during the
  # day; deleted with the instance. The nightly dated snapshots are the long-lived copies.
  backup_retention_period  = 1
  delete_automated_backups = true
  copy_tags_to_snapshot    = true

  # The destroy workflow has already taken a dated snapshot. A Terraform final snapshot would
  # need a new unique name every night.
  skip_final_snapshot = true
  deletion_protection = false # destroyed every night by design

  lifecycle {
    # The next day's apply passes a newer snapshot; that must never replace a running database
    ignore_changes = [snapshot_identifier]
  }
}
