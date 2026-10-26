# Interface for the cluster (ESO reads db_host from here) and CI scripts (ADR-0019). Never secrets.
module "contract" {
  source = "../../modules/ssm_contract"

  path        = local.contract_path
  description = "Published by live/04_data"
  values = {
    db_host       = aws_db_instance.prod.address
    db_port       = tostring(aws_db_instance.prod.port)
    db_identifier = aws_db_instance.prod.identifier
    db_secret_arn = aws_secretsmanager_secret.db.arn
  }
}
