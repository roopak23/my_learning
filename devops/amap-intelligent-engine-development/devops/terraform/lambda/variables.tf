
variable "prefix" {
  description = "prefix for kms key name"
}

variable "env" {
  description = "Environemtm where kms will bde deployrd :dev,sit"
}

variable "account_num" {
  description = "Account ID where KMS will be deployed"
}

variable "region" {
  description = "Region where KMS will be deployed"
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Log retention in days"
}


variable "eks_config" {
  description = "EKS configuration"
}

variable "schedule_start_env" {
  description = "Cron expresion when evironemnt should be started"
}


variable "schedule_stop_env" {
  description = "Cron expresion when evironemnt should be stopped"
}


variable "sns_topic_arn" {
  description = "sns where messages will be send"
}

variable "network_setup" {
  description = "VPC to deploy lambda"
}
