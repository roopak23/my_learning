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
aws_account_num  = "904458240716"
# AWS account username for the environment
aws_account_user = "group-amap-powerdev"
# time at which the environment will be sarted
schedule_start_env = "cron(0 19 ? * * *)"
# time at which the environment will be stopped (as a cost saving measure)
schedule_stop_env = "cron(0 17 * * ? *)"

# CloudWatch log retention name for EKS events and Lambda executions
logs_config = {
  eks_logs = {
    cluster     = 7
    dataplane   = 7
    performance = 7
    application = 14
    host        = 7
  }
  cloudwatch_lambdas_log_group_retention_in_days = 7
}

deployrolearn = "arn:aws:iam::904458240716:role/amap-uatdeploy-role"

deploysitid = "uatdeploy"

# roles defined in EKS configuration
roles = [{
  rolearn  = "arn:aws:sts::904458240716:assumed-role/group-amap-powerdev"
  username = "group-amap-powerdev"
  groups   = ["system:masters"]
},
{
  rolearn  = "arn:aws:sts::904458240716:assumed-role/foxtel-hawkeye-uat-jenkins-role"
  username = "foxtel-hawkeye-uat-jenkins-role"
  groups   = ["system:masters"]
}
]

# users defined in EKS configuration
users = [{
  userarn  = "arn:aws:iam::904458240716:role/group-amap-powerdev"
  username = "group-amap-powerdev"
  groups   = ["system:masters"]
},
{
  userarn  = "arn:aws:iam::904458240716:role/foxtel-hawkeye-uat-jenkins-role"
  username = "foxtel-hawkeye-uat-jenkins-role"
  groups   = ["system:masters"]
}
]

# SSL certificate ARN used in 
certificate_arn = "arn:aws:acm:ap-southeast-2:904458240716:certificate/9668d075-d0d1-4b51-a4f8-4dbe10df12ed"

# network configuration for the provided VPC
network = {
  # hostname for the private resources (available only within client's network)
  route_53_private_site     = "uatamapie.foxtel.com.au"
  #hostname for the public resources (availabe from the Internet)
  route_53_public_site      = "pub.uatamapie.foxtel.com.au"
  # ID of the configured VPC
  vpc_id                    = "vpc-09c669901dcdf71cd"
  # CIDR network address block configured for VPC
  vpc_cidr_block            = "10.109.192.0/19"
  # private subnet CIDR network address blocks for subnets in availability zones a, b, c respectively
  vpc_private_subnets_cidrs = ["10.109.200.0/21", "10.109.208.0/21", "10.109.216.0/21"]
  # private subnet IDs for subnets in availability zones a, b, c respectively
  vpc_private_subnets_ids = ["subnet-001c482731652adc4", "subnet-07df65956c5087f76", "subnet-0345dc89216e84db9"]
  # public subnet CIDR network address blocks for subnets in availability zones a, b, c respectively
  vpc_public_subnets_cidrs  = ["10.109.194.0/23", "10.109.196.0/23", "10.109.198.0/23"]
  # vpn_security_group_id     = "sg-0a071f27939c21924"
  citrix_cidrs  =  ["10.77.92.0/22"]
}

# RDS MySQL database configuration
rds = {
  # private database subnet CIDR network address blocks for subnets in availability zones a, b respectively
  vpc_rds_subnets_cidrs = ["10.109.192.128/25", "10.109.193.0/25"]
  # private database subnet IDs for subnets in availability zones a, b respectively
  vpc_rds_subnets_ids = ["subnet-02dcbea8884e2ac4a", "subnet-01b05535c4b1ecd15"]
  # MySQL admin user
  rds_user              = "dm3admin"
  # MySQL admin password (to be changed after environment creation)
  rds_password          = "replace_me"
  # RDS instance size (eg. db.t3.medium)
  instance_type         = "db.r7g.2xlarge"
  # MySQL connection port (default is 3306)
  port                  = 3306

  backup_retention_period = 7
}

# EC2 common configuration
ec2_common = {
  # EC2 deployer SSH public key, created or imported in AWS console
  ec2_deployer_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCq4h4fescCfbEGc+eOc6TXlAfZ7WG4XfNfl2VhwIK9xpbA4Iqj6NpDqFyf5IEejl3P0B4Ob/5lFZij8fy2oi0jT9MRFzBEi+QrREtlFQOkjTvFFmvPMteWFyg+/01BPOlqvGMJ4LGlrWF9PTByM8xku54SIWRAxZE2D+YBXuftCW5hNXEV5kKoiew8N5OzCHENHFFYL76eyzIZa6okhjqdFH6upaGvgF8cvYnU5CdnjRiRFTUK2MXi7Usq299G7R4eMT6xXAPJ1Q/aEQViMP1tSJqayh+8RzemterAoowknai4C9qTlT+F12b+Xdfx5kLTTj8fEUTToFu6rZvNr+Z5BTWnsQBHklEl/qXsOalgGmjD9BlwsdNJpdmQ879iGFfiTPrpJxjRHpn84eZydauTEpDaSKKRlk9KUugHjgkhZf7B890cjk/JtkrYgNhknqy9KtL9rcNTPDhHARurrgiCmWArtn0sb2th/Iw2ywhsln7Wy1r6IrzEe1uNsTvTRc8= foxtel-hawkeye-uat-deployer-key"
  # AMI ID for the latest Amazon Linux 2023 x86_64 AMI in the environment's region
  ec2_ami                 = "ami-0e326862c8e74c0fe"
}
## SEGTOOL Variables ## 
#segtool = {
#  install_segtool           = true
#  ec2_segtool_instance_type = "t3a.medium"
#  ec2_segtool_ami           = "ami-04b1c88a6bbd48f8e"
#  site                      = "segtooldev.avs-accenture.com"
#}

jenkins = {
  install_jenkins = true
  instance_type    = "t2.medium"
  ec2_ami             = "ami-0e326862c8e74c0fe"
}

## EKS Variables ## 
eks_config = {
  # instance sizes, desired, minimum and maximum sizes for the EC2 autoscaling groups
  eks_node_foundation_group_instance_type = "t3a.2xlarge"
  eks_node_foundation_group_min_size      = 2
  eks_node_foundation_group_des_size      = 2
  eks_node_foundation_group_max_size      = 4
  eks_node_data_group_instance_type       = "t3a.xlarge"
  eks_node_data_group_min_size            = 2
  eks_node_data_group_des_size            = 2
  eks_node_data_group_max_size            = 4
  eks_node_management_group_instance_type = "m5d.xlarge"
  eks_node_management_group_min_size      = 0
  eks_node_management_group_des_size      = 0
  eks_node_management_group_max_size      = 4
  # EC2 autoscaling group IDs (to be filled after environment is created)
  auto_scaling_group_ids                  = "['foxtel-hawkeye-uat-eks-management-group2024061204554091940000002e','foxtel-hawkeye-uat-eks-foundation-group20240612055238195100000002','foxtel-hawkeye-uat-eks-data-group20240612055238197100000003']"
  # version of the EKS cluster, latest available is recommended
  eks_cluster_version                     = "1.30"

  # latest versions of required EKS addons matching the EKS cluster version set above
  "addons" = [
    {
      name    = "kube-proxy"
      version = "v1.30.3-eksbuild.5"
      configuration_values = "{}"
    },
    {
      name    = "vpc-cni"
      version = "v1.18.3-eksbuild.3"
      configuration_values = "{}"
    },
    {
      name    = "coredns"
      version = "v1.11.3-eksbuild.1"
      configuration_values = "{}"
    },    
    {
      name                 = "amazon-cloudwatch-observability"
      version              = "v2.1.0-eksbuild.1"
      configuration_values = "{}"
    }
  ]

}

## bellow is a list of application that will be accesible via VPN without tunneling
emr_vpn_additional_rules = [
  {
    "port" : 10000
    "descritpion" : "Allow HIVE access from VPN(CITRIX"
  },
  {
    "port" : 22
    "descritpion" : "Allow SSH access from VPN(CITRIX)"
  }
  ,
  {
    "port" : 8998
    "descritpion" : "Allow Livy access from VPN(CITRIX))"
  }
  ,
  {
    "port" : 8890
    "descritpion" : "Allow Zepelin access from VPN(CITRIX)"
  },
  {
    "port" : 80
    "descritpion" : "Allow Ganglia access from VPN(CITRIX)"
  },
  {
    "port" : 8188
    "descritpion" : "Allow access to Timelineservice WEB UI from VPN(CITRIX)"
  },
  {
    "port" : 8042
    "descritpion" : "Allow access to nodemeanger WEB UI from VPN(CITRIX)"
  }
  ,
  {
    "port" : 19888
    "descritpion" : "Allow access to mapreduce JOb history WEB UI from VPN(CITRIX)"
  }
  ,
  {
    "port" : 8088
    "descritpion" : "Allow access to mapreduce resourcemanager WEB UI from VPN(CITRIX)"
  }
   ,
  {
    "port" : 18080
    "descritpion" : "Allow access to Spark history WEB UI from VPN(CITRIX)"
  }
]
