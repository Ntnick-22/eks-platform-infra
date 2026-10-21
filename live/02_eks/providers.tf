provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Layer     = "02_eks"
      ManagedBy = "terraform"
      Repo      = "eks-platform-infra"
    }
  }
}
