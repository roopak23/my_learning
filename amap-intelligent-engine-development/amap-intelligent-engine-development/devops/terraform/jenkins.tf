

module "ec2_jenkins" {
  source                   = "./ec2/jenkins"
  count                    = var.jenkins.install_jenkins == true ? 1 : 0
  prefix                   = var.prefix
  ec2_deploy_key_name      = module.ec2_common.deploy_key_name
  jenkins_instance_profile = module.ec2_common.jenkins_instance_profile
  ec2_ami                  = var.jenkins.ec2_ami
  subnet_id                = var.network.vpc_private_subnets_ids[1]
  vpc_id                   = var.network.vpc_id
  instance_type            = var.jenkins.instance_type
  # vpn_security_group_id = var.network.vpn_security_group_id
  vpc_cidr_block           = var.network.vpc_cidr_block
}

