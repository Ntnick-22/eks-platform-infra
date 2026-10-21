output "arn" {
  description = "Boundary policy ARN (roles pass it as permissions_boundary)"
  value       = aws_iam_policy.this.arn
}
