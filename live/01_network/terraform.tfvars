region   = "eu-west-1"
project  = "myeks"
vpc_cidr = "10.20.0.0/16"

# Daily defaults. Drill days: az_count = 3 / nat_mode = "per_az". Demo days: enable_interface_endpoints = true.
az_count                   = 2
nat_mode                   = "single"
nat_instance_type          = "t4g.nano"
enable_interface_endpoints = false
