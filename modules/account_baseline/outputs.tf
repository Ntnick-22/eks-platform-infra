output "ebs_encryption_by_default" {
  description = "Whether new EBS volumes in this region are encrypted by default"
  value       = aws_ebs_encryption_by_default.this.enabled
}
