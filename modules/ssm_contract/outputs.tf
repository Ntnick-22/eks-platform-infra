output "parameter_names" {
  description = "Full parameter names keyed like var.values, e.g. { vpc_id = \"/myeks/network/vpc_id\" }"
  value       = { for k, p in aws_ssm_parameter.this : k => p.name }
}

output "parameter_arns" {
  description = "Parameter ARNs keyed like var.values (for IAM policies of consumers)"
  value       = { for k, p in aws_ssm_parameter.this : k => p.arn }
}
