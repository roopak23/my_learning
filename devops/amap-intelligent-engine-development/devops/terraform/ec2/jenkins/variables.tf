## Definitions are in ../../globals.tfvars

variable "vpc_id" {
  description = "AwS region"
}

variable "instance_type" {
  description = "segtool instance type"
}

variable "ec2_ami" {
  description = "ami-0aab712d6363da7f9" # ap-southeast-2 specific AMI
}

variable "subnet_id" {
  description = "subnet to use"
}

variable "jenkins_instance_profile" {
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

variable "vpc_cidr_block" {
  description = "VPC cidr block"
}