
module "kms_sns_key" {
  source         = "./kms/sns"
  prefix         = var.prefix
  aws_account_id = var.aws_account_num
}


# module "sns-cw-alarms" {
#   source                                 = "./sns-notifications"
#   sns_topic_name                         = "${var.prefix}-cw-alerts"
#   allowed_aws_services_for_sns_published = ["cloudwatch.amazonaws.com"]
#   kms_master_key_id                      = module.kms_sns_key.key_arn
#   aws_account_id                         = var.aws_account_num
# }


module "sns-etl-monitoring" {
  source                                 = "./sns-notifications"
  sns_topic_name                         = "${var.prefix}-etl-monitor"
  allowed_aws_services_for_sns_published = ["lambda.amazonaws.com"]
  kms_master_key_id                      = module.kms_sns_key.key_arn
  aws_account_id                         = var.aws_account_num
}


# module "rds-alarms" {
#   source            = "./cloudwatch/rds-alarms"
#   actions_alarm     = module.sns-cw-alarms.sns_topic_arn
#   actions_ok        = module.sns-cw-alarms.sns_topic_arn
#   db_instance_id    = module.rds.id
#   db_instance_class = module.rds.instance_classs
# }



