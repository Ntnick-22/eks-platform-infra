terraform {
  backend "s3" {
    key = "02_eks/terraform.tfstate"
  }
}
