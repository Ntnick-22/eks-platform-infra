terraform {
  backend "s3" {
    key = "00_bootstrap/terraform.tfstate"
  }
}