
variable "site" {
  description = "AWS secret key to use"
}


variable "env" {
  description = "Environment: dev/qa/prod"
}

variable "certificate_arn" {
  description = "Environment: dev/qa/prod"
}

variable "aws_account_user" {
  description = "Environment: dev/qa/prod"
}


variable "prefix" {
  description = "Environment: dev/qa/prod"
}

variable "aws_account_num" {
  description = "aws account number"
}

variable "aws_region" {
  description = "aws account number"
}


variable "logs_config" {
  description = "aws account number"
}


variable "rds" {
  description = "RDS configuration"
}

#variable "segtool" {
#  description = "SegTool Configurations"
#}

variable "eks_config" {
  description = "cidrs for subnets"
}

variable "network" {
  description = "temp instance type"
}

variable "ec2_common" {
  description = "temp subnet"
}

variable "users" {
  description = "temp subnet"
}

variable "roles" {
  description = "temp subnet"
}

variable "schedule_start_env" {
  description = "prefix for kms key name"
}

variable "schedule_stop_env" {
  description = "prefix for kms key name"
}

#variable "splunk_agents" {
#  description = "CIRDs of splunk agents"
#}

#variable "splunk_port" {
#  description = "port to splunk agents"
#}

variable "jenkins" {
  description = "jenkins variables"
}


variable "deployrolearn" {
  description = "deployrolearn"
}

variable "deploysitid" {
  description = "deploysitid"
}

variable "emr_vpn_additional_rules" {
  description = "Additonal ports to  be opened for EMR"
}
