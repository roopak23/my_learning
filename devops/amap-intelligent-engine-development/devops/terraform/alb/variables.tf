
variable "vpc_private_subnets_ids" {
  description = "subnet to place the alb in. Should be private subnet"
}

variable "prefix" {
  description = "environment"
}

variable "vpc_id" {
  description = "environment"
}

variable "segtool_site" {
  description = "environment"
}

variable "segtool_ip" {
  description = "private ip address of tableau"
}

variable "segtool_sec_group_id" {
  description = "ec2 security groups to be used for the alb"
}

variable "certificate_arn" {
  description = "SSL certificate for alb"
}

# variable "vpn_security_group_id" {
#   description = "ec2 security groups to be used for the alb"
# }

