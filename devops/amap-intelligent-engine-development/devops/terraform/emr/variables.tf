variable "prefix" {
  description = "Environment prefix e.g amap-dm-product-dev"
}

variable "aws_region" {
  description = "Region where EMR will be deployed"
}

variable "aws_account_num" {
  description = "AWS account ID"
}

variable "data_bucket_name" {
  description = "S3 bucked where data will be stored"
}


variable "logs_bucket_name" {
  description = "S3 bucked where emr logs  will be stored"
}

variable "kms_emr_key" {
  description = "EMR KMS key for security context"
}
