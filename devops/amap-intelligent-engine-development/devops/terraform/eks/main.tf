/*

EKS SERVICE CREATES A DEFAULT CLUSTER PRIMARY SECURITY GROUP THAT CANNOT BE MANAGED IN TERRAFORM
NAME OF THIS GROUP STARTS WITH eks-cluster-sg-<cluster name>
AFTER CLUSTER IS CREATED, APPLY THE FOLLOWING OUTBOUND RULES TO THIS SECURITY GROUP:
- outbound HTTPS (TCP port 443) to 0.0.0.0/0
- outbount HTTP (TCP port 80) to 0.0.0.0/0
- all ports and protocols to VPC CIDR block, eg. 192.168.0.0/19

*/

/*
### cluster security group
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.prefix}-eks_cluster_sg"
  description = "Created based on default EKS Cluster Security Group with limited egress"
  vpc_id      = var.vpc_id
  tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned",
    "aws:eks:cluster-name" = "${local.eks_cluster_name}"
  }
}

resource "aws_security_group_rule" "eks_cluster_ingress_sgr" {
  description              = "Ingress for EKS Cluster"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  self                     = true
  security_group_id        = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "eks_cluster_egress_it_sgr" {
  description              = "Egress from EKS Cluster to internet"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "eks_cluster_egress_its_sgr" {
  description              = "Egress from EKS Cluster to internet"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "eks_cluster_egress_vpc_sgr" {
  description              = "Egress from EKS Cluster to VPC"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [var.vpc_cidr_block]
  security_group_id        = aws_security_group.eks_cluster_sg.id
}
*/

### node security group
  resource "aws_security_group" "eks_node_sg" {
  name        = "${local.eks_cluster_name}_node_sg"
  description = "Created based on default EKS Node Security Group with limited egress"
  vpc_id      = var.vpc_id
  tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "eks_node_ingress_from_add_sgr" {
  description              = "Ingress for pods running extension API servers on port 443 to receive communication from cluster control plane"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_security_group_id
  security_group_id        = aws_security_group.eks_node_sg.id
}

resource "aws_security_group_rule" "eks_node_ingress_from_self_sgr" {
  description              = "Ingress for allowing nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  self                     = true
  security_group_id        = aws_security_group.eks_node_sg.id
}

resource "aws_security_group_rule" "eks_node_ingress_from_add_highports_sgr" {
  description              = "Ingress for workers pods to receive communication from the cluster control plane"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_security_group_id
  security_group_id        = aws_security_group.eks_node_sg.id
}

resource "aws_security_group_rule" "eks_node_egress_it_sgr" {
  description              = "Egress from EKS Node to internet"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.eks_node_sg.id
}

resource "aws_security_group_rule" "eks_node_egress_its_sgr" {
  description              = "Egress from EKS Node to internet"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.eks_node_sg.id
}

resource "aws_security_group_rule" "eks_node_egress_vpc_sgr" {
  description              = "Egress from EKS Node to VPC"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [var.vpc_cidr_block]
  security_group_id        = aws_security_group.eks_node_sg.id
}

/*

### additional security group
resource "aws_security_group" "eks_additional_sg" {
  name        = "${var.prefix}-eks_additional_sg"
  description = "Created based on default EKS Additional Security Group with limited egress"
  vpc_id      = var.vpc_id

}

resource "aws_security_group_rule" "eks_additional_ingress_sgr" {
  description              = "Ingress for pods to communicate with the EKS cluster API."
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_node_sg.id
  security_group_id        = aws_security_group.eks_additional_sg.id
}

resource "aws_security_group_rule" "eks_additional_egress_it_sgr" {
  description              = "Egress from EKS Cluster to internet"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.eks_additional_sg.id
}

resource "aws_security_group_rule" "eks_additional_egress_its_sgr" {
  description              = "Egress from EKS Cluster to internet"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.eks_additional_sg.id
}

resource "aws_security_group_rule" "eks_additional_egress_vpc_sgr" {
  description              = "Egress from EKS Cluster to VPC"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [var.vpc_cidr_block]
  security_group_id        = aws_security_group.eks_additional_sg.id
}

*/
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "=17.10.0"

  cluster_name                           = local.eks_cluster_name
  cluster_version                        = var.eks_config.eks_cluster_version
  cluster_log_retention_in_days = var.retention_days["cluster"]
 
  subnets = var.vpc_private_subnets_ids
  workers_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonElasticMapReduceFullAccess",
    "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    aws_iam_policy.alb_policy.arn,
    aws_iam_policy.aws_dns_ebs_csi_policy.arn
  ]
  map_roles    = var.roles # [var.role,var.ec2_role]
  map_accounts = [var.aws_account_num]
  map_users    = var.users #[var.user,var.ec2_user]

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_create_endpoint_private_access_sg_rule = true
  cluster_endpoint_private_access_cidrs  =  [var.jenkins_cidr]
  

  tags = {
    Name = "${local.eks_cluster_name}"
  }

  vpc_id = var.vpc_id

  cluster_egress_cidrs = [var.vpc_cidr_block]

  #cluster_create_security_group = false
  worker_create_security_group = false
  #cluster_security_group_id = aws_security_group.eks_cluster_sg.id
  worker_security_group_id = aws_security_group.eks_node_sg.id
  #worker_additional_security_group_ids = [aws_security_group.eks_additional_sg.id]

  worker_groups_launch_template = [
    {
      name                      = "foundation-group"
      instance_type             = var.eks_config.eks_node_foundation_group_instance_type
      asg_desired_capacity      = var.eks_config.eks_node_foundation_group_des_size
      asg_min_size              = var.eks_config.eks_node_foundation_group_min_size
      asg_max_size              = var.eks_config.eks_node_foundation_group_max_size
      kubelet_extra_args        = "--node-labels=group=foundation"
      iam_instance_profile_name = aws_iam_role.eks_worker_role.name
      root_encrypted            = true
      cpu_credits      = "unlimited"
      tags = [
        {
          key                 = "Name",
          value               = "${local.eks_cluster_name}-foundation-group",
          propagate_at_launch = "true"
        },
        {
          key                 = "Environment",
          value               = var.env
          propagate_at_launch = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${local.eks_cluster_name}",
          value               = "owned",
          propagate_at_launch = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/enabled",
          value               = "TRUE",
          propagate_at_launch = "true"
        },
        {
          key                 = "kubernetes.io/role/internal-elb",
          value               = "owned",
          propagate_at_launch = "true"
        }
      ]
    },
    {
      name                      = "data-group"
      instance_type             = var.eks_config.eks_node_data_group_instance_type
      asg_desired_capacity      = var.eks_config.eks_node_data_group_des_size
      asg_min_size              = var.eks_config.eks_node_data_group_min_size
      asg_max_size              = var.eks_config.eks_node_data_group_max_size
      kubelet_extra_args        = "--node-labels=group=data"
      iam_instance_profile_name = aws_iam_role.eks_worker_role.name
      root_encrypted            = true
      cpu_credits      = "unlimited"
      # target_group_arns             = var.alb_target_group_arn
      tags = [
        {
          key                 = "Name",
          value               = "${local.eks_cluster_name}-data-group",
          propagate_at_launch = "true"
        },
        {
          key                 = "Environment",
          value               = var.env
          propagate_at_launch = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${local.eks_cluster_name}",
          value               = "owned",
          propagate_at_launch = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/enabled",
          value               = "TRUE",
          propagate_at_launch = "true"
        }
      ]
    },
    {
      name                      = "management-group"
      instance_type             = var.eks_config.eks_node_management_group_instance_type
      asg_desired_capacity      = var.eks_config.eks_node_management_group_des_size
      asg_min_size              = var.eks_config.eks_node_management_group_min_size
      asg_max_size              = var.eks_config.eks_node_management_group_max_size
      kubelet_extra_args        = "--node-labels=group=management,machineType=rapid"
      iam_instance_profile_name = aws_iam_role.eks_worker_role.name
      root_encrypted            = true
      cpu_credits      = "unlimited"
      # target_group_arns             = var.alb_target_group_arn
      tags = [
        {
          key                 = "Name",
          value               = "${local.eks_cluster_name}-management-group",
          propagate_at_launch = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${local.eks_cluster_name}",
          value               = "owned",
          propagate_at_launch = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/enabled",
          value               = "TRUE",
          propagate_at_launch = "true"
        }
      ]
    },
  ]
}

resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.eks_config.addons : addon.name => addon }
  cluster_name      = module.eks.cluster_id
  addon_name        = each.value.name
  addon_version     = each.value.version
  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

// This policy attaches to each worker node inside the cluster.
resource "aws_iam_role" "eks_worker_role" {
  name = "${local.eks_cluster_name}_worker_role"
  path = "/"
  tags = {
    Name = "${local.eks_cluster_name}_worker_role"

  }

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Sid": ""
        }
    ]
}
EOF
}

# // This policy is to allow the Kubernetes worker nodes to be able to assume a role. This is necessary in being able to connect to the Cleint S3 bucket since Client has provided us a role we can assume for S3 access. 
# resource "aws_iam_policy" "eks_workers_assume_role_policy" {
#   name        = "${local.eks_cluster_name}-assume_role_police"
#   path        = "/"
#   description = "This policy is to allow the Kubernetes worker nodes to be able to assume a role."
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : [
#                 "sts:AssumeRole",
#                 "s3:ListBucket",
#                 "s3:GetObject"
#             ],
#         "Resource" : [
#                 "*",
#                 "arn:aws:s3:::foxtel-hawkeye-dev-s3-data",
#                 "arn:aws:s3:::foxtel-hawkeye-dev-s3-data/*"
#             ]
#       }
#     ]
#   })
# }

// This policy is to allow the external application load balancer to have access to the resources inside the kubernetes cluster
resource "aws_iam_policy" "alb_policy" {
  name        = "${local.eks_cluster_name}-alb-policy"
  path        = "/"
  description = "ALB Policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : "CreateSecurityGroup"
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ] 
        #removed condition as per https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/v2.4.4/docs/install/iam_policy.json#L160-L165
        #,
        # "Condition" : {
        #   "Null" : {
        #     "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
        #     "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
        #   }
        # }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ],
        "Resource" : "*"
      }
    ]
  })
}

// Policy for AWS EBS CSI driver
resource "aws_iam_policy" "aws_dns_ebs_csi_policy" {
  name        = "${local.eks_cluster_name}-aws_dns_ebs_csi_policy"
  path        = "/"
  description = "This policy is to allow the Kubernetes worker nodes to create volumes using AWS EBS CSI driver."
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect" : "Allow",
        "Action" : [
                "sts:AssumeRole",
                "s3:ListBucket",
                "s3:GetObject"
            ],
        "Resource" : [
                "*",
                "arn:aws:s3:::foxtel-hawkeye-dev-s3-data",
                "arn:aws:s3:::foxtel-hawkeye-dev-s3-data/*"
            ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/kubernetes.io/created-for/pvc/name": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    }
  ]
  })
}



resource "aws_cloudwatch_log_group" "dataplane" {
  name              = "/aws/containerinsights/${local.eks_cluster_name}/dataplane"
  retention_in_days = var.retention_days["dataplane"]

  tags = {
    Name = "${local.eks_cluster_name}/dataplane"
  }
}


resource "aws_cloudwatch_log_group" "performance" {
  name              = "/aws/containerinsights/${local.eks_cluster_name}/performance"
  retention_in_days = var.retention_days["performance"]

  tags = {
    Name = "${local.eks_cluster_name}/performance"
  }
}


resource "aws_cloudwatch_log_group" "host" {
  name              = "/aws/containerinsights/${local.eks_cluster_name}/host"
  retention_in_days = var.retention_days["host"]

  tags = {
    Name = "${local.eks_cluster_name}/host"
  }
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/containerinsights/${local.eks_cluster_name}/application"
  retention_in_days = var.retention_days["application"]

  tags = {
    Name = "${var.prefix}-${local.eks_cluster_name}/application"
  }
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

