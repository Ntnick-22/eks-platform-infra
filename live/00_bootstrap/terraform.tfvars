region           = "eu-west-1"
project          = "myeks"
name_prefix      = "ntnick-myeks"
budget_limit_usd = 30
# Immutable subject (owner/repo IDs) - from: gh api repos/Ntnick-22/eks-platform-infra/actions/oidc/customization/sub
github_oidc_sub_prefix = "repo:Ntnick-22@190462806/eks-platform-infra@1421296705"
# App repo (eks-platform-app): its CI may push images to ECR from main only
github_app_oidc_sub_prefix = "repo:Ntnick-22@190462806/eks-platform-app@1432153002"
ecr_repositories           = ["backend", "frontend"]

# CI apply: GitHub environment "infra" (main only, owner approval); nightly destroy: "infra-destroy" (main only).
# Add a layer here when CI starts applying it.
github_apply_environment   = "infra"
github_destroy_environment = "infra-destroy"
ci_applied_layers          = ["01_network", "02_eks", "03_platform"]

# Public DNS: the zone already exists (other projects use it too); the platform owns only eks.<zone>
hosted_zone_name = "nt-nick.link"
platform_domain  = "eks.nt-nick.link"

# budget_alert_emails comes from TF_VAR_budget_alert_emails / GitHub secret, never from this file.
