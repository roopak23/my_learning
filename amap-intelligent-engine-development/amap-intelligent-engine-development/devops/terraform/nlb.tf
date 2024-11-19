
module "nlb" {
  # count               = var.network.vpn.install_vpn
  source                  = "./nlb"
  prefix                  = var.prefix
  certificate_arn         = var.certificate_arn
  vpc_private_subnets_ids = var.network.vpc_private_subnets_ids
  vpc_id                  = var.network.vpc_id
  vpc_cidr_block          = var.network.vpc_cidr_block
  citrix_cidrs            = var.network.citrix_cidrs
  jenkinsip               = module.ec2_jenkins[0].ec2_jenkins_private_ip
}

