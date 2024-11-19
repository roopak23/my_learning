## Globals ##
## If VPC is already provided, please fill out the global variables for VPCs below:
# AWS site name (not including shortened environment name)
site             = "foxtel-hawkeye"
# shortened environment name
env              = "dev"
# prefix used for AWS resource names (site name and short environment name)
prefix           = "foxtel-hawkeye-dev"
# AWS region in which the resources will be created
aws_region       = "ap-southeast-2"
# AWS account number for the environment
aws_account_num  = "787189406110"
# AWS account username for the environment
aws_account_user = "group-amap-powerdev"
# time at which the environment will be sarted
schedule_start_env = "cron(0 19 ? * * *)"
# time at which the environment will be stopped (as a cost saving measure)
schedule_stop_env = "cron(0 17 * * ? *)"

# CloudWatch log retention name for EKS events and Lambda executions
logs_config = {
  cloudwatch_eks_log_group_retention_in_days     = 7
  cloudwatch_lambdas_log_group_retention_in_days = 7
}

deployrolearn = "arn:aws:iam::787189406110:role/amap-testdeploy-role"

deploysitid = "testdeploy"

# roles defined in EKS configuration
roles = [{
  rolearn  = "arn:aws:sts::787189406110:assumed-role/group-amap-powerdev"
  username = "group-amap-powerdev"
  groups   = ["system:masters"]
},
{
  rolearn  = "arn:aws:sts::787189406110:assumed-role/foxtel-hawkeye-dev-jenkins-role"
  username = "foxtel-hawkeye-dev-jenkins-role"
  groups   = ["system:masters"]
}
]



# users defined in EKS configuration
users = [{
  userarn  = "arn:aws:iam::787189406110:role/group-amap-powerdev"
  username = "group-amap-powerdev"
  groups   = ["system:masters"]
},
{
  userarn  = "arn:aws:iam::787189406110:role/foxtel-hawkeye-dev-jenkins-role"
  username = "foxtel-hawkeye-dev-jenkins-role"
  groups   = ["system:masters"]
}
]

# SSL certificate ARN used in 
certificate_arn = "arn:aws:acm:ap-southeast-2:787189406110:certificate/551a5a7d-740d-4956-ae7e-63170dac7675"

# network configuration for the provided VPC
network = {
  # hostname for the private resources (available only within client's network)
  route_53_private_site     = "devamapie.foxtel.com.au"
  #hostname for the public resources (availabe from the Internet)
  route_53_public_site      = "pub.devamapie.foxtel.com.au"
  # ID of the configured VPC
  vpc_id                    = "vpc-022fafb9a0a670e8d"
  # CIDR network address block configured for VPC
  vpc_cidr_block            = "10.109.128.0/19"
  # private subnet CIDR network address blocks for subnets in availability zones a, b, c respectively
  vpc_private_subnets_cidrs = ["10.109.136.0/21", "10.109.144.0/21", "10.109.152.0/21"]
  # private subnet IDs for subnets in availability zones a, b, c respectively
  vpc_private_subnets_ids = ["subnet-099c86c169cab8eaf", "subnet-00b1b84a4e6d09a9e", "subnet-0235178a9eb9b030b"]
  # public subnet CIDR network address blocks for subnets in availability zones a, b, c respectively
  vpc_public_subnets_cidrs  = ["10.109.130.0/23", "10.109.132.0/23", "10.109.134.0/23"]
  # vpn_security_group_id     = "sg-0a071f27939c21924"
  citrix_cidrs  =  ["10.77.92.0/22"]
}

# RDS MySQL database configuration
rds = {
  # private database subnet CIDR network address blocks for subnets in availability zones a, b respectively
  vpc_rds_subnets_cidrs = ["10.109.129.128/25", "10.109.129.0/25"]
  # private database subnet IDs for subnets in availability zones a, b respectively
  vpc_rds_subnets_ids = ["subnet-0ee99d87af72438f6", "subnet-033b4a36dd25b1a10"]
  # MySQL admin user
  rds_user              = "dm3admin"
  # MySQL admin password (to be changed after environment creation)
  rds_password          = "replace_me"
  # RDS instance size (eg. db.t3.medium)
  instance_type         = "db.t3.medium"
  # MySQL connection port (default is 3306)
  port                  = 3306
}

# EC2 common configuration
ec2_common = {
  # EC2 deployer SSH public key, created or imported in AWS console
  ec2_deployer_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvM8QEU3K5cQckM2TWhaG522cZbj6FolVVskHCOH79GWQDf8CMfM8tKSsnhq0aLvo9Hjf3kZEA4wSxT8c0e821QAwoRsz81iUoCJFMGbnBZa3LxCDrnVKf2nnubqtgWo812WXV/SMy37LFQSGX/taREukANRWKuNAamTGLu3K73jVvAxDxdbcznU1L2i0y698w2rJtW8xx5xwSboPoiHj+XhM7surG/qLHasYzzaR3ElfhABZCbapLIlukkvtojWYvl+50a0ufiVMxF8fM94yQCMF6/9e+f64RNxWY299MLhSb2jXJKrFeCyqkad4X6tMqNzGqbNOn6ug0nuIt7ezL foxtel-hawkeye-dev-deployer-key"
  # AMI ID for the latest Amazon Linux 2023 x86_64 AMI in the environment's region
  ec2_ami                 = "ami-00ffa321011c2611f"
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
  ec2_ami             = "ami-00ffa321011c2611f"
}

## EKS Variables ## 
eks_config = {
  # instance sizes, desired, minimum and maximum sizes for the EC2 autoscaling groups
  eks_node_foundation_group_instance_type = "t3a.xlarge"
  eks_node_foundation_group_min_size      = 0
  eks_node_foundation_group_des_size      = 2
  eks_node_foundation_group_max_size      = 4
  eks_node_data_group_instance_type       = "t3a.medium"
  eks_node_data_group_min_size            = 0
  eks_node_data_group_des_size            = 2
  eks_node_data_group_max_size            = 3
  eks_node_management_group_instance_type = "m5d.xlarge"
  eks_node_management_group_min_size      = 0
  eks_node_management_group_des_size      = 0
  eks_node_management_group_max_size      = 3
  # EC2 autoscaling group IDs (to be filled after environment is created)
  auto_scaling_group_ids                  = "['foxtel-hawkeye-dev-eks-management-group2023090110164612370000001f','foxtel-hawkeye-dev-eks-foundation-group20230901101646123700000020','foxtel-hawkeye-dev-eks-data-group20230901101646123800000021']"
  # version of the EKS cluster, latest available is recommended
  eks_cluster_version                     = "1.27"

  # latest versions of required EKS addons matching the EKS cluster version set above
  "addons" = [
    {
      name    = "kube-proxy"
      version = "v1.27.1-eksbuild.1"
    },
    {
      name    = "vpc-cni"
      version = "v1.12.6-eksbuild.2"
    },
    {
      name    = "coredns"
      version = "v1.10.1-eksbuild.1"
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



