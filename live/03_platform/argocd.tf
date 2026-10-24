locals {
  argo_helm_repo   = "https://argoproj.github.io/argo-helm"
  argocd_namespace = "argocd"
}

# Argo CD itself. Upgrade by changing argocd_chart_version in tfvars (PR → plan → apply).
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = local.argocd_namespace
  create_namespace = true
  repository       = local.argo_helm_repo
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  values           = [file("${path.module}/helm-values/argocd.yaml")]
  wait             = true
  timeout          = 600
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

  depends_on = [kubernetes_secret_v1.gitops_repo] # root can only sync once the repo credential exists
}
