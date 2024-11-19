
variable "sns_topic_name" {
  type = string
}

variable "allowed_aws_services_for_sns_published" {
  type        = list(string)
  description = "AWS services that will have permission to publish to SNS topic. Used when no external JSON policy is used"
  default     = []
}

variable "kms_master_key_id" {
  type        = string
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK."
  default     = "alias/aws/sns"
}

variable "encryption_enabled" {
  type        = bool
  description = "Whether or not to use encryption for SNS Topic. If set to `true` and no custom value for KMS key (kms_master_key_id) is provided, it uses the default `alias/aws/sns` KMS key."
  default     = true
}

variable "subscription_enabled" {
  type    = bool
  default = true
}

variable "create_sns" {
  type    = bool
  default = true
}

variable "sns_arn" {
  type    = string
  default = ""
}

variable "allowed_iam_arns_for_sns_publish" {
  type        = list(string)
  description = "IAM role/user ARNs that will have permission to publish to SNS topic. Used when no external json policy is used."
  default     = []
}

variable "sns_topic_policy_json" {
  type        = string
  description = "The fully-formed AWS policy as JSON"
  default     = ""
}

variable "delivery_policy" {
  type        = string
  description = "The SNS delivery policy as JSON."
  default     = null
}

variable "fifo_topic" {
  type        = bool
  description = "Whether or not to create a FIFO (first-in-first-out) topic"
  default     = false
}

variable "content_based_deduplication" {
  type        = bool
  description = "Enable content-based deduplication for FIFO topics"
  default     = false
}


variable "aws_account_id" {
  type        = string
  description = "Owner of the SNS topic."
}