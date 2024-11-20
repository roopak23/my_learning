
module "ec2_common" {
  source                  = "./ec2/common"
  prefix                  = var.prefix
  aws_region              = var.aws_region
  ec2_deployer_public_key = var.ec2_common.ec2_deployer_public_key
  data_bucket_name        = module.s3_data.bucket_name
  logs_bucket_name        = module.s3_logs.bucket_name
  app_bucket_name         = module.s3_app.bucket_name
  aws_account_num         = var.aws_account_num
}


module "ecr" {
  source = "./ecr"
}


module "lambdas" {
  source                                 = "./lambda"
  prefix                                 = var.prefix
  eks_config                             = var.eks_config
  env                                    = var.env
  schedule_stop_env                      = var.schedule_stop_env
  schedule_start_env                     = var.schedule_start_env
  account_num                            = var.aws_account_num
  region                                 = var.aws_region
  cloudwatch_log_group_retention_in_days = var.logs_config.cloudwatch_lambdas_log_group_retention_in_days
  sns_topic_arn                          = module.sns-etl-monitoring.sns_topic_arn
  network_setup = { subnet_ids = var.network.vpc_private_subnets_ids
  security_group_ids = [module.eks.eks_cluster_security_groups] }
}


resource "aws_route53_zone" "private_site" {
 name = "${var.network.route_53_private_site}"
 tags = {
   Name = "${var.network.route_53_private_site}"
   Environment = "${var.env}"
 }
 vpc {
   vpc_id      = var.network.vpc_id
   vpc_region  = var.aws_region
 }
}

resource "aws_route53_record" "jenkins_nlb" {
  name    = "jenkins.${aws_route53_zone.private_site.name}"
  zone_id = aws_route53_zone.private_site.zone_id
  type    = "A"
  alias {
    name                   = module.nlb.nlb_dns_name
    zone_id                = module.nlb.nlb_zone_id
    evaluate_target_health = true
  }
}
