variable "aws_region" {
    description = "ap-southeast-2"
}

variable "env" {
  description = "environment"
}

variable "vpc_private_subnets_ids" {
  description = "private subnets"
}

variable "aws_account_num" {
  description = "aws account number"
}

variable "aws_account_user" {
  description = "aws account user"
}

variable "users" {
  description = "user"
}

variable "eks_config" {
  description = "eks_configuration"
}


variable "roles" {
  description = "role to add in eks so it can be seen in console"
}

variable "vpc_id" {
  description = "VPC for EKS cluster"
}

variable "retention_days" {
  type = map(string)
  description = "retention days for logs"
}

variable "prefix" {
  description = "VPC for EKS cluster"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
}

locals {
  eks_cluster_name = "${var.cluster_name}"
}
variable "cluster_name" {
  description = "Name of eks cluster"
  
}
variable "jenkins_cidr" {
  description = "Name of eks cluster"
  
}


