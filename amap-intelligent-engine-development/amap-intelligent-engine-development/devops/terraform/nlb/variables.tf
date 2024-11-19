
variable "vpc_private_subnets_ids" {
   description = "subnet to place the nlb in. Should be private subnet"
 }

variable "prefix" {
  description = "environment"
}

variable "vpc_id" {
  description = "network"
}

variable "certificate_arn" {
  description = "SSL certificate for alb"
}

variable "vpc_cidr_block" {
  description = "VPC cidr block"
}

# variable "vpn_security_group_id" {
#   description = "ec2 security groups to be used for the alb"
# }

variable "citrix_cidrs" {
  description = "subnetnet cidr for private access"
}
variable "jenkinsip" {
  description = "jenkins"
}
