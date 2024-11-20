module "emr" {
  source           = "./emr"
  prefix           = var.prefix
  aws_account_num  = var.aws_account_num
  data_bucket_name = module.s3_data.bucket_name
  logs_bucket_name = module.s3_logs.bucket_name
  aws_region       = var.aws_region
  kms_emr_key      = module.kms_emr_key.key_arn
}


module "emr_security_group" {
  source                   = "./emr_security_group"
  prefix                   = var.prefix
  vpc_id                   = var.network.vpc_id
  eks_security_groups      = module.eks.eks_cluster_security_groups
  env                      = var.env
  aws_region               = var.aws_region
  vpc_cidr_block           = var.network.vpc_cidr_block
  citrix_cidrs             = var.network.citrix_cidrs
  emr_vpn_additional_rules = var.emr_vpn_additional_rules
}

module "kms_emr_key" {
  source         = "./kms/emr"
  prefix         = var.prefix
  aws_account_id = var.aws_account_num
}




