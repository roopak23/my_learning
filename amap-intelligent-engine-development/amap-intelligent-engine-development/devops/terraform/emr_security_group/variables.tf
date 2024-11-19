variable "vpc_id" {
  description = "Vpc id where EMR will be deployed"
}

variable "aws_region" {
  description = "AWS region where EMR will be deployed"
}

variable "prefix" {
  description = "Environemnt profix e.g amap-product-dev"
}

variable "env" {
  description = "Environment e.g dev,sit"
}

variable "eks_security_groups" {
  description = "Eks security groups to add to ingress to access EMR frm EKS nodes"
}

# variable "vpn_security_group_id" {
#   description = "Subnetnet CIDR - to access EMR from VPN ( only Accenture Env)"
# }

variable "vpc_cidr_block" {
  description = "VPC CDIRs where EMR will be created (this needs to be changed )"
}


variable "citrix_cidrs" {
  description = "subnetnet cidr for private access"
}


variable "emr_vpn_additional_rules" {
  description = "Additonal ports to  be opened for EMR"
}



