module "rds" {
  source                    = "./rds"
  vpc_rds_subnets           = var.rds.vpc_rds_subnets_ids
  vpc_id                    = var.network.vpc_id
  eks_security_groups       = module.eks.eks_cluster_security_groups
  env                       = var.env
  prefix                    = var.prefix
  aws_region                = var.aws_region
  vpc_private_subnets_cidrs = var.network.vpc_private_subnets_cidrs
  vpc_segtool_subnets_cidrs = var.network.vpc_private_subnets_cidrs[1]
  vpc_private_subnets_ids   = var.network.vpc_private_subnets_ids
  instance_type             = var.rds.instance_type
  rds_user                  = var.rds.rds_user
  rds_password              = var.rds.rds_password
  rds_port                  = var.rds.port
  citrix_cidrs              = var.network.citrix_cidrs
  vpc_cidr_block           = var.network.vpc_cidr_block
  backup_retention_period  = var.rds.backup_retention_period
}

