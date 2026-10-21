data "aws_partition" "current" {}

locals {
  managed_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id                   = var.vpc_id
  control_plane_subnet_ids = var.control_plane_subnet_ids
  subnet_ids               = var.node_subnet_ids

  # Public + private endpoint (ADR-0017). Nodes use the private one inside the VPC.
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # Access entries only, no aws-auth ConfigMap. Admins are listed explicitly:
  # "creator gets admin" would depend on who happened to run apply (laptop or CI).
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = false
  access_entries = {
    for label, arn in var.admin_principal_arns : label => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # Pod Identity instead of IRSA: no IAM OIDC provider per cluster, simpler role trust
  enable_irsa = false

  # Secrets are envelope-encrypted with an AWS-owned key by default. A customer KMS key per
  # daily cluster would leave a key pending deletion every night (ADR-0015).
  create_kms_key    = false
  encryption_config = null

  enabled_log_types                      = var.control_plane_log_types
  create_cloudwatch_log_group            = length(var.control_plane_log_types) > 0
  cloudwatch_log_group_retention_in_days = 1

  iam_role_permissions_boundary = var.permissions_boundary_arn

  addons = {
    # Before the nodes: prefix delegation must be on when the first node starts,
    # or it gets a few single IPs instead of /28 prefixes (~110 pods per node).
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
        enableNetworkPolicy = "true" # NetworkPolicies enforced by the VPC CNI itself (ADR-0015)
      })
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy     = {}
    coredns        = {}
    metrics-server = {}
    aws-ebs-csi-driver = {
      # gp3 StorageClass marked default: since 1.30 EKS no longer makes gp2 the default.
      # No extra volume tags needed: the add-on runs the driver with --k8s-tag-cluster-id=<cluster>,
      # so every volume already gets kubernetes.io/cluster/<cluster>=owned (scripts/leftover-check.sh
      # relies on it). Setting that tag ourselves crashes the driver: the kubernetes.io prefix is reserved.
      configuration_values = jsonencode({
        defaultStorageClass = { enabled = true }
      })
      pod_identity_association = [{
        role_arn        = module.ebs_csi_role.arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  eks_managed_node_groups = {
    spot = {
      name           = "${var.name}-spot"
      ami_type       = "AL2023_ARM_64_STANDARD"
      capacity_type  = "SPOT"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size_gb
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # IMDSv2 only, hop limit 1: a pod's request to 169.254.169.254 needs 2 hops and is dropped,
      # so pods cannot borrow the node role. They get their own role through Pod Identity.
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      iam_role_name                 = "${var.name}-node"
      iam_role_permissions_boundary = var.permissions_boundary_arn
      iam_role_additional_policies = {
        # Session Manager shell on nodes for debugging: no SSH key, no port 22
        ssm = "${local.managed_policy_prefix}/AmazonSSMManagedInstanceCore"
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.name
  }
}

# EBS CSI driver: creates and attaches gp3 volumes for PVCs (Prometheus, Loki WAL, Vault)
module "ebs_csi_role" {
  source = "../pod_identity_role"

  name                     = "${var.name}-ebs-csi"
  permissions_boundary_arn = var.permissions_boundary_arn
  # Note the path: this AWS-managed policy lives under service-role/, unlike the EKS ones
  managed_policy_arns = ["${local.managed_policy_prefix}/service-role/AmazonEBSCSIDriverPolicy"]
  # No association here: the EKS add-on creates it (pod_identity_association above)
}
