## Definitions are in ../../globals.tfvars

variable "aws_region" {
  description = "AwS region"
}

variable "vpc_id" {
  description = "AwS region"
}

variable "ec2_segtool_instance_type" {
  description = "segtool instance type"
}

variable "env" {
  description = "environment"
}

variable "ec2_ami" {
  description = "ami-0aab712d6363da7f9" # ap-southeast-2 specific AMI
}

variable "segtool_subnet_id" {
  description = "subnet to use"
}

variable "ec2_instance_profile" {
  description = "subnet to use"
}

variable "ec2_deploy_key_name" {
  description = "subnet to use"
}

variable "prefix" {
  description = "subnet to use"
}

# variable "vpn_security_group_id" {
#   description = "subnet to use"
# }

variable "rds_security_group" {
  description = "subnet to use"
}

variable "vpc_private_subnets_cidrs" {
  description = "subnet to use"
}


variable "rds_port" {
  description = "subnet to use"
}

variable "splunk_agents" {
  description = "CIRDs of splunk agents"
}

variable "splunk_port" {
  description = "port to splunk agents"
}


