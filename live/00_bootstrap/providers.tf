provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Layer     = "00_bootstrap"
      ManagedBy = "terraform"
      Repo      = "eks-platform-infra"
    }
  }
}
