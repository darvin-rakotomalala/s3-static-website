variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}
