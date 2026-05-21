output "s3_key_arn" {
  description = "KMS key for S3 bucket encryption"
  value       = aws_kms_key.s3_key.arn
}
