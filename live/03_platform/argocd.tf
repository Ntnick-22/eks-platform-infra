locals {
  argo_helm_repo   = "https://argoproj.github.io/argo-helm"
  argocd_namespace = "argocd"
  argocd_host      = "argocd.${local.platform_domain}"
  # Referenced from dex.config as $<secret>:<key>; Argo CD resolves it at runtime
  argocd_github_oauth_secret = "argocd-github-oauth"
}

# Argo CD itself. Upgrade by changing argocd_chart_version in tfvars (PR → plan → apply).
# Static settings in the values file; what depends on other layers or tfvars is added here.
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = local.argocd_namespace
  create_namespace = true
  repository       = local.argo_helm_repo
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  values = [
    file("${path.module}/helm-values/argocd.yaml"),
    yamlencode({
      global = { domain = local.argocd_host } # also the login URL Dex redirects back to
      configs = {
        cm = {
          "dex.config" = yamlencode({
            connectors = [{
              type = "github"
              id   = "github"
              name = "GitHub"
              config = {
                clientID     = var.argocd_github_client_id
                clientSecret = format("$%s:clientSecret", local.argocd_github_oauth_secret)
              }
            }]
          })
        }
        rbac = {
          "policy.csv" = join("\n", [for login in var.argocd_admins : "g, ${login}, role:admin"])
        }
      }
    }),
  ]
  wait    = true
  timeout = 600
}

# GitHub OAuth client secret for Dex: Secrets Manager → write-only Secret, never in state.
# Argo CD only resolves $<secret>:<key> references in Secrets labelled part-of=argocd.
ephemeral "aws_secretsmanager_secret_version" "argocd_github_oauth" {
  secret_id = data.aws_ssm_parameter.argocd_github_oauth_secret_arn.insecure_value
}

resource "kubernetes_secret_v1" "argocd_github_oauth" {
  metadata {
    name      = local.argocd_github_oauth_secret
    namespace = local.argocd_namespace
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data_wo = {
    clientSecret = ephemeral.aws_secretsmanager_secret_version.argocd_github_oauth.secret_string
  }
  data_wo_revision = 1

  depends_on = [helm_release.argocd] # the chart creates the argocd namespace
}

# Private gitops repo: the read-only deploy key goes from Secrets Manager straight into a
# write-only Secret field. Ephemeral read + data_wo = the key is never in plan output or state.
# A rotated key is picked up on the next daily rebuild (or bump data_wo_revision).
ephemeral "aws_secretsmanager_secret_version" "gitops_deploy_key" {
  secret_id = data.aws_ssm_parameter.gitops_deploy_key_secret_arn.insecure_value
}

# Argo CD's declarative repository credential: found by the secret-type label, matched by URL
resource "kubernetes_secret_v1" "gitops_repo" {
  metadata {
    name      = "gitops-repo"
    namespace = local.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  # data and data_wo cannot be combined, so the whole Secret is write-only.
  # Bump data_wo_revision when type/url change: Terraform cannot diff write-only values.
  data_wo = {
    type          = "git"
    url           = var.gitops_repo_url
    sshPrivateKey = ephemeral.aws_secretsmanager_secret_version.gitops_deploy_key.secret_string
  }
  data_wo_revision = 1

  depends_on = [helm_release.argocd] # the chart creates the argocd namespace
}

# Root app-of-apps: syncs apps/ in the gitops repo; everything after this comes from git.
# Created via the argocd-apps chart: a kubernetes_manifest would need the Application CRD
# at plan time, which does not exist on a fresh cluster.
# No finalizer: deleting the root must not cascade; teardown is the cluster destroy.
resource "helm_release" "argocd_root" {
  name       = "argocd-root"
  namespace  = local.argocd_namespace
  repository = local.argo_helm_repo
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace = local.argocd_namespace
        project   = "default"
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = "main"
          path           = "apps"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = local.argocd_namespace
        }
        syncPolicy = {
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["ServerSideApply=true"]
        }
      }
    }
  })]

  # Root can only sync once the repo credential exists. The ingress add-ons come first so the apps'
  # Ingresses are served at once, and on destroy they are removed last: they still clean up the
  # ALB and DNS records of the apps the destroy workflow drains before.
  depends_on = [
    kubernetes_secret_v1.gitops_repo,
    helm_release.aws_load_balancer_controller,
    helm_release.external_dns,
  ]
}
