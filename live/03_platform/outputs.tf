output "argocd_namespace" {
  description = "Namespace Argo CD runs in"
  value       = module.argocd_bootstrap.namespace
}

output "argocd_ui_command" {
  description = "Open the Argo CD UI on https://localhost:8080 (user admin)"
  value       = "kubectl -n argocd port-forward svc/argocd-server 8080:443  # password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
