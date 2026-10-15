# Shared S3 backend settings for every layer.
# Usage: terraform init -backend-config=../backend.hcl
# Each layer's backend.tf sets only its own key.
bucket       = "ntnick-myeks-tfstate"
region       = "eu-west-1"
use_lockfile = true
encrypt      = true
