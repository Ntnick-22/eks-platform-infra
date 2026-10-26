provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Layer     = "04_data"
      ManagedBy = "terraform"
      Repo      = "eks-platform-infra"
    }
  }
}
