terraform {
  backend "s3" {
    key = "01_network/terraform.tfstate"
  }
}
