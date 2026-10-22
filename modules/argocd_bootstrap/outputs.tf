output "namespace" {
  description = "Namespace Argo CD runs in"
  value       = helm_release.argocd.namespace
}

output "chart_version" {
  description = "Installed argo-cd chart version"
  value       = helm_release.argocd.version
}
