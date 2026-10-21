terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.59" # terraform-aws-modules/eks 21.x needs >= 6.59
    }
  }
}
