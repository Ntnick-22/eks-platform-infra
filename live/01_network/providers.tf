provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Layer     = "01_network"
      ManagedBy = "terraform"
      Repo      = "eks-platform-infra"
    }
  }
}
