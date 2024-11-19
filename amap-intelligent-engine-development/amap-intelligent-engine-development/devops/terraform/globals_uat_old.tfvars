## Globals ##
## If VPC is already provided, please fill out the global variables for VPCs below:
# AWS site name (not including shortened environment name)
site             = "foxtel-hawkeye"
# shortened environment name
env              = "uat"
# prefix used for AWS resource names (site name and short environment name)
prefix           = "foxtel-hawkeye-uat"
# AWS region in which the resources will be created
aws_region       = "ap-southeast-2"
# AWS account number for the environment
#aws_account_num  = "904458240716"
# AWS account username for the environment
#aws_account_user = "group-amap-powerdev"
# time at which the environment will be sarted
#schedule_start_env = "cron(0 2 ? * MON-FRI *)"
# time at which the environment will be stopped (as a cost saving measure)
#schedule_stop_env = "cron(0 19 * * ? *)"

# CloudWatch log retention name for EKS events and Lambda executions
#logs_config = {
 # cloudwatch_eks_log_group_retention_in_days     = 7
#  cloudwatch_lambdas_log_group_retention_in_days = 7
#}

#deployrolearn = "arn:aws:iam::904458240716:role/amap-uatdeploy-role"

#deployuatid = "uatdeploy"

# roles defined in EKS configuration
#roles = [{
#  rolearn  = "arn:aws:sts::904458240716:assumed-role/group-amap-powerdev"
#  username = "group-amap-powerdev"
#  groups   = ["system:masters"]
#},
#{
#  rolearn  = "arn:aws:sts::904458240716:assumed-role/foxtel-hawkeye-uat-jenkins-role"
#  username = "foxtel-hawkeye-uat-jenkins-role"
#  groups   = ["system:masters"]
#}
#]



