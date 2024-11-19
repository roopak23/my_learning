
variable "vpc_rds_subnets" {
  description = "rds subnets"
}

variable "vpc_id" {
  description = "vpc to use"
}

variable "env" {
  description = "eks security groups to add to ingress of rds"
}

variable "aws_region" {
  description = "eks security groups to add to ingress of rds"
}

variable "prefix" {
  description = "eks security groups to add to ingress of rds"
}


variable "eks_security_groups" {
  description = "eks security groups to add to ingress of rds"
}

variable "vpc_private_subnets_cidrs" {
  description = "subnet of EMR cluster"
}

variable "vpc_private_subnets_ids" {
  description = "VPC private subnets"
}


variable "vpc_segtool_subnets_cidrs" {
  description = "subnet of segtoo cluster"
}

# variable "vpn_security_group_id" {
#   description = "subnet of segtoo cluster"
# }

variable "instance_type" {
  description = "subnetnet CIDR"
}

variable "rds_user" {
  description = "subnetnet CIDR"
}

variable "rds_password" {
  description = "subnetnet CIDR"
}

variable "rds_port" {
  description = "subnetnet CIDR"
}


variable "citrix_cidrs" {
  description = "subnetnet cidr for private access"
}

variable "vpc_cidr_block" {
  description = "VPC cidr block"
}

variable "backup_retention_period" {
  description = "backup_retention_period"
}


