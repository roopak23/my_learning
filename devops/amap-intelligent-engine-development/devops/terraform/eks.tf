

module "eks" {
  source                                 = "./eks"
  aws_region                             = var.aws_region
  env                                    = var.env
  vpc_private_subnets_ids                = var.network.vpc_private_subnets_ids
  aws_account_num                        = var.aws_account_num
  aws_account_user                       = var.aws_account_user
  users                                  = var.users
  eks_config                             = var.eks_config
  roles                                  = var.roles
  vpc_id                                 = var.network.vpc_id
  prefix                                 = var.prefix
  vpc_cidr_block                         = var.network.vpc_cidr_block
  retention_days                         = var.logs_config.eks_logs
  cluster_name                           = "${var.prefix}-eks"
  jenkins_cidr                           = "${module.ec2_jenkins[0].ec2_jenkins_private_ip}/32"
}


module "service_account" {
  source                      = "./service_account"
  env                         = var.env
  aws_region                  = var.aws_region
  svc_eks_cluster_oidc_issuer = module.eks.eks_cluster_oidc_issuer
  prefix                      = var.prefix
}

