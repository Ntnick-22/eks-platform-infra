terraform {
  backend "s3" {
    key = "03_platform/terraform.tfstate"
  }
}
