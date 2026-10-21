region  = "eu-west-1"
project = "myeks"

# N-1: newest is 1.37; 1.36 is in standard support until 2027-08 (upgrade drill to 1.37 later)
kubernetes_version = "1.36"

# Laptop user that runs kubectl / k9s (the CI apply role is added from the bootstrap contract)
cluster_admin_iam_users = ["nyein-thu"]

# Daily defaults. Drill days: node_az_count = 2 (needs 01_network up in both AZs, it always is),
# control_plane_log_types = ["audit", "authenticator"].
node_az_count           = 1
node_instance_types     = ["t4g.large", "m6g.large", "m7g.large"]
node_min_size           = 2
node_max_size           = 3
node_desired_size       = 2
control_plane_log_types = []
