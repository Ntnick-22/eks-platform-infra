region  = "eu-west-1"
project = "myeks"

# Prod database (dev uses in-cluster postgres-dev with fake data). Same major as dev and CI.
postgres_version     = "17.9"
instance_class       = "db.t4g.micro"
allocated_storage_gb = 20
db_name              = "app"
master_username      = "app_admin"

# restore_snapshot_identifier is not set here: CI passes the newest snapshot
# (TF_VAR_restore_snapshot_identifier="$(scripts/latest-db-snapshot.sh)"); do the same on the laptop.
