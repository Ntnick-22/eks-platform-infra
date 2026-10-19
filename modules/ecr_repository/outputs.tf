output "name" {
  description = "Repository name"
  value       = aws_ecr_repository.this.name
}

output "arn" {
  description = "Repository ARN (for IAM policies, e.g. the CI push role)"
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "Registry URL to tag and push images to"
  value       = aws_ecr_repository.this.repository_url
}
