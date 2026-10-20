locals {
  # One EKS cluster per project (ADR-0004): the cluster is called "myeks".
  cluster_name = var.project

  contract_path = "/${var.project}/network"
}
