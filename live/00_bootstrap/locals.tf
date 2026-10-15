locals {
  tfstate_bucket_name = "${var.name_prefix}-tfstate"

  # The budget watches the whole account, not only this project.
  budget_name = "account-monthly-cost"
}
