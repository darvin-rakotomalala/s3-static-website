#########################################################
# BACKEND
#########################################################

module "bootstrap" {
  source        = "./modules/bootstrap"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  bucket_name   = var.bucket_name
  table_name    = var.table_name
}

#########################################################
# IAM
#########################################################

module "iam" {
  source             = "./modules/iam"
  current_account_id = data.aws_caller_identity.current.account_id
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  github_org         = var.github_org
  github_repo        = var.github_repo
}

#########################################################
# ROUTE 53
#########################################################

module "route53" {
  source                                 = "./modules/route53"
  current_account_id                     = data.aws_caller_identity.current.account_id
  naming_prefix                          = local.naming_prefix
  common_tags                            = local.common_tags
  cf_website_domain_name                 = module.cloudfront.cf_website_domain_name
  cf_website_hosted_zone_id              = module.cloudfront.cf_website_hosted_zone_id
  data_zone_id                           = data.aws_route53_zone.existing.zone_id
  domain_name                            = var.domain_name
  data_aws_route53_zone_existing_zone_id = data.aws_route53_zone.existing.zone_id
}

#########################################################
# ACM
#########################################################

module "acm" {
  source        = "./modules/acm"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  data_zone_id  = data.aws_route53_zone.existing.zone_id
  domain_name   = var.domain_name
}

#########################################################
# KMS
#########################################################

module "kms" {
  source             = "./modules/kms"
  current_account_id = data.aws_caller_identity.current.account_id
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
}

#########################################################
# S3 WEBSITE AND CLOUDFRONT LOGGING
#########################################################

module "s3" {
  source             = "./modules/s3"
  current_account_id = data.aws_caller_identity.current.account_id
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  s3_key_arn         = module.kms.s3_key_arn
}

#########################################################
# CLOUDFRONT
#########################################################

module "cloudfront" {
  source                                     = "./modules/cloudfront"
  naming_prefix                              = local.naming_prefix
  common_tags                                = local.common_tags
  acm_certificate_arn                        = module.acm.acm_certificate_arn
  cloudfront_ops_bucket                      = module.s3.cloudfront_ops_bucket
  cloudfront_ops_bucket_domain_name          = module.s3.cloudfront_ops_bucket_domain_name
  cloudfront_ops_bucket_regional_domain_name = module.s3.cloudfront_ops_bucket_regional_domain_name
  data_cf_caching_optimized_id               = data.aws_cloudfront_cache_policy.caching_optimized.id
  data_cf_cors_s3_origin_id                  = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  data_cf_security_headers_id                = data.aws_cloudfront_response_headers_policy.security_headers.id
  domain_name                                = var.domain_name
  s3_bucket_cloudfront_ops_arn               = module.s3.s3_bucket_cloudfront_ops_arn
  s3_bucket_cloudfront_ops_id                = module.s3.s3_bucket_cloudfront_ops_id
  s3_bucket_website_arn                      = module.s3.s3_bucket_website_arn
  s3_bucket_website_id                       = module.s3.s3_bucket_website_id
  website_bucket                             = module.s3.website_bucket
  website_bucket_regional_domain_name        = module.s3.website_bucket_regional_domain_name
  waf_web_acl_arn                            = module.waf.cf_waf_acl_arn
}

#########################################################
# WAF
#########################################################

module "waf" {
  source        = "./modules/waf"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
}

#########################################################
# CLOUDWATCH
#########################################################

module "cloudwatch" {
  source             = "./modules/cloudwatch"
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  cf_distribution_id = module.cloudfront.distribution_id
  sns_topic_arn      = [module.sns.sns_topic_arn]
}

#########################################################
# SNS
#########################################################

module "sns" {
  source              = "./modules/sns"
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
  email_subscriptions = var.email_subscriptions
}

#########################################################
## UPLOAD HTML FILES TO S3 BUCKET
#########################################################
locals {
  mime_types = {
    "html"  = "text/html"
    "css"   = "text/css"
    "js"    = "application/javascript"
    "json"  = "application/json"
    "webp"  = "image/webp"
    "png"   = "image/png"
    "jpg"   = "image/jpeg"
    "jpeg"  = "image/jpeg"
    "svg"   = "image/svg+xml"
    "ico"   = "image/x-icon"
    "woff"  = "font/woff"
    "woff2" = "font/woff2"
    "ttf"   = "font/ttf"
    "txt"   = "text/plain"
  }
}

resource "aws_s3_object" "provision_source_files" {
  bucket   = module.s3.s3_bucket_website_id
  for_each = fileset("${var.source_files}/", "**/*.*")
  key      = each.value
  source   = "${var.source_files}/${each.value}"
  # Extract the file extension and look up the correct MIME type
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
  etag         = filemd5("${var.source_files}/${each.value}")
  # cache_control = startswith(each.value, "assets/") ? "public, max-age=31536000, immutable" : "no-cache"
}
