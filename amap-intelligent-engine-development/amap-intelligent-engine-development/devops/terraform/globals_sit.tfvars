## Globals ##
## If VPC is already provided, please fill out the global variables for VPCs below:
# AWS site name (not including shortened environment name)
site             = "foxtel-hawkeye"
# shortened environment name
env              = "sit"
# prefix used for AWS resource names (site name and short environment name)
prefix           = "foxtel-hawkeye-sit"
# AWS region in which the resources will be created
aws_region       = "ap-southeast-2"
# AWS account number for the environment
aws_account_num  = "956659591835"
# AWS account username for the environment
aws_account_user = "group-amap-powerdev"
# time at which the environment will be sarted
schedule_start_env = "cron(0 2 ? * MON-FRI *)"
# time at which the environment will be stopped (as a cost saving measure)
schedule_stop_env = "cron(0 19 * * ? *)"

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

deployrolearn = "arn:aws:iam::956659591835:role/amap-sitdeploy-role"

deploysitid = "sitdeploy"

# roles defined in EKS configuration
roles = [{
  rolearn  = "arn:aws:sts::956659591835:assumed-role/group-amap-powerdev"
  username = "group-amap-powerdev"
  groups   = ["system:masters"]
},
{
  rolearn  = "arn:aws:sts::956659591835:assumed-role/foxtel-hawkeye-sit-jenkins-role"
  username = "foxtel-hawkeye-sit-jenkins-role"
  groups   = ["system:masters"]
}
]



# users defined in EKS configuration
users = [{
  userarn  = "arn:aws:iam::956659591835:role/group-amap-powerdev"
  username = "group-amap-powerdev"
  groups   = ["system:masters"]
},
{
  userarn  = "arn:aws:iam::956659591835:role/foxtel-hawkeye-sit-jenkins-role"
  username = "foxtel-hawkeye-sit-jenkins-role"
  groups   = ["system:masters"]
}
]

# SSL certificate ARN used in 
certificate_arn = "arn:aws:acm:ap-southeast-2:956659591835:certificate/fb0d4f8c-7923-4f97-a2f5-79a9f6a8a696"

# network configuration for the provided VPC
network = {
  # hostname for the private resources (available only within client's network)
  route_53_private_site     = "sitamapie.foxtel.com.au"
  #hostname for the public resources (availabe from the Internet)
  route_53_public_site      = "pub.sitamapie.foxtel.com.au"
  # ID of the configured VPC
  vpc_id                    = "vpc-008479ddf33595faf"
  # CIDR network address block configured for VPC
  vpc_cidr_block            = "10.109.160.0/19"
  # private subnet CIDR network address blocks for subnets in availability zones a, b, c respectively
  vpc_private_subnets_cidrs = ["10.109.168.0/21", "10.109.176.0/21", "10.109.184.0/21"]
  # private subnet IDs for subnets in availability zones a, b, c respectively
  vpc_private_subnets_ids = ["subnet-07d3fc407c6db2eb3", "subnet-06470dc529bcef887", "subnet-07f68f2a4ab2e30ed"]
  # public subnet CIDR network address blocks for subnets in availability zones a, b, c respectively
  vpc_public_subnets_cidrs  = ["10.109.162.0/23", "10.109.164.0/23", "10.109.166.0/23"]
  # vpn_security_group_id     = "sg-0a071f27939c21924"
  citrix_cidrs  =  ["10.77.92.0/22"]
}

# RDS MySQL database configuration
rds = {
  # private database subnet CIDR network address blocks for subnets in availability zones a, b respectively
  vpc_rds_subnets_cidrs = ["10.109.160.128/25", "10.109.161.0/25"]
  # private database subnet IDs for subnets in availability zones a, b respectively
  vpc_rds_subnets_ids = ["subnet-004dfa76c1021a49d", "subnet-0debd2f05e1990620"]
  # MySQL admin user
  rds_user              = "dm3admin"
  # MySQL admin password (to be changed after environment creation)
  rds_password          = "replace_me"
  # RDS instance size (eg. db.t3.medium)
  instance_type         = "db.t3.xlarge"
  # MySQL connection port (default is 3306)
  port                  = 3306
  
  backup_retention_period = 3
}

# EC2 common configuration
ec2_common = {
  # EC2 deployer SSH public key, created or imported in AWS console
  ec2_deployer_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCu0n++EftsMvTvR1W4bHK9Hdd3LwtM/Ht1fOLPzCAitbJTG4xofawAeO07gcYnC4MCOFVtJnRqutaEMvDqNXshaDTaos70PLmsBA+lkCWFz4d1reWzGcYfILPsgWl/WfLVvXjUX/HEOkU3CcYT2tguuNi82/vCQmAQMaBr7em8NQAh9NN7DiP3RJ5X/dcVdydH6Hhz2iw/coMUvSvab0aMirU9fVLthUL/a+4+BPMwwTzkwz8MZQROJvdFmzWrcq/MVR6Y9dPJbYY5eCUZrZiJNkb/+gagL/DOyisn0cIH4lIXncZv3lgS5yb+LzCGX27nWfE6tSP0JKouV3j9l0DgwJfGo0uQzFTJGz91SM9t6kn89dR6pc2QpyQMIAUS/p9MCVb322+pNNrJUgqmY/GADJM1YwXdVIIOFEKl22IEACITa47IlQaiSHHOcROD0arIrvm1DeVvBIsNRQfy9/V3HhrYh2l6waar1mqBMqhFaklfkuxrBgdtw3yqf4pwdQM= roopak.murty.gade@BDC7-LX-4K2YPP3"
  # AMI ID for the latest Amazon Linux 2023 x86_64 AMI in the environment's region
  ec2_ami                 = "ami-07b5c2e394fccab6e"
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
  ec2_ami             = "ami-07b5c2e394fccab6e"
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
  auto_scaling_group_ids                  = "['foxtel-hawkeye-sit-eks-management-group2023110907135315740000001d','foxtel-hawkeye-sit-eks-foundation-group20231109073624590700000002','foxtel-hawkeye-sit-eks-data-group20231109073624578300000001']"
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
