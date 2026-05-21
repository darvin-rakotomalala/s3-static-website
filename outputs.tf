output "backend_s3_bucket_name" {
  value = module.bootstrap.s3_bucket_name
}

output "backend_dynamodb_table_name" {
  value = module.bootstrap.dynamodb_table_name
}

output "iam_role_terraform_execution_arn" {
  value = module.iam.iam_role_terraform_execution_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = module.cloudfront.distribution_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront Distribution Hosted Zone ID"
  value       = module.cloudfront.distribution_hosted_zone_id
}

output "website_bucket_name" {
  description = "S3 Bucket Name for website content"
  value       = module.s3.website_bucket
}

output "website_bucket_arn" {
  description = "S3 Bucket ARN for website content"
  value       = module.s3.s3_bucket_website_arn
}

output "logs_bucket_name" {
  description = "S3 Bucket Name for CloudFront logs"
  value       = module.s3.cloudfront_ops_bucket
}

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = data.aws_route53_zone.existing.zone_id
}

output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = module.acm.acm_certificate_arn
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.waf.cf_waf_acl_arn
}

output "website_origin_access_control_id" {
  description = "Origin Access Control ID"
  value       = module.cloudfront.website_origin_access_control_id
}

output "error_pages_origin_access_control_id" {
  description = "Error pages Origin Access Control ID"
  value       = module.cloudfront.error_pages_origin_access_control_id
}

output "website_url" {
  description = "Website URL"
  value       = "https://${var.domain_name}"
}

output "www_website_url" {
  description = "WWW Website URL"
  value       = "https://www.${var.domain_name}"
}

output "ds_record" {
  description = "DS record to add to your domain registrar"
  value       = module.route53.ds_record_dnssec
}

output "ksk_status" {
  description = "Current status of the Key Signing Key"
  value       = module.route53.ksk_status_dnssec
}

output "ds_record_KSK" {
  description = "Formatted DS record for registrar"
  value       = module.route53.ds_record_KSK
}
