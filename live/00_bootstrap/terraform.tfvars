region           = "eu-west-1"
project          = "myeks"
name_prefix      = "ntnick-myeks"
budget_limit_usd = 30
# Immutable subject (owner/repo IDs) - from: gh api repos/Ntnick-22/eks-platform-infra/actions/oidc/customization/sub
github_oidc_sub_prefix = "repo:Ntnick-22@190462806/eks-platform-infra@1421296705"
ecr_repositories       = ["backend", "frontend"]

# CI apply: GitHub environment "infra" (main only, owner approval). Add a layer here when CI starts applying it.
github_apply_environment = "infra"
ci_applied_layers        = ["01_network"]

# budget_alert_emails comes from TF_VAR_budget_alert_emails / GitHub secret, never from this file.
