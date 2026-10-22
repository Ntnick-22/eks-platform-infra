locals {
  helm_repo = "https://argoproj.github.io/argo-helm"
}

# Terraform owns Argo CD: upgrade by changing the chart version in tfvars (PR → plan → apply)
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.namespace
  create_namespace = true
  repository       = local.helm_repo
  chart            = "argo-cd"
  version          = var.chart_version
  wait             = true
  timeout          = 600

  values = [yamlencode({
    dex           = { enabled = false } # port-forward + admin for now; SSO later
    notifications = { enabled = false }
  })]
}

# Root app-of-apps, via the argocd-apps chart: a kubernetes_manifest would need the
# Application CRD at plan time, which does not exist on a fresh cluster.
# No finalizer: deleting the root must not cascade; teardown is the cluster destroy.
resource "helm_release" "root" {
  name       = "argocd-root"
  namespace  = var.namespace
  repository = local.helm_repo
  chart      = "argocd-apps"
  version    = var.apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace = var.namespace
        project   = "default"
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_revision
          path           = var.root_path
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = var.namespace
        }
        syncPolicy = {
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["ServerSideApply=true"]
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
