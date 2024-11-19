
resource "aws_key_pair" "deployer_access" {
  key_name   = "${var.prefix}-deployer-key"
  public_key = var.ec2_deployer_public_key
  tags = {
    Name = "${var.prefix}-deployer-key"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
  tags = {
    Name = "${var.prefix}-ec2-instance-profile"
  }
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "${var.prefix}-jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
  tags = {
    Name = "${var.prefix}-jenkins-instance-profile"
  }
}

resource "aws_iam_policy" "ec2_role_policy" {
  name = "${var.prefix}-ec2-role-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketTagging",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:DeleteObject",
          "ec2:AssignPrivateIpAddresses"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.data_bucket_name}",
          "arn:aws:s3:::${var.data_bucket_name}/*",
          "arn:aws:s3:::${var.logs_bucket_name}",
          "arn:aws:s3:::${var.logs_bucket_name}/*",
          "arn:aws:s3:::${var.app_bucket_name}",
          "arn:aws:s3:::${var.app_bucket_name}/*",
          "arn:aws:ec2:${var.aws_region}:${var.aws_account_num}:network-interface/*"
        ]
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey"
        ],
        "Resource" : [
          "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:key/*",
          "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:alias/*"
        ]
      },
      {
        "Sid" : "VisualEditor3",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetBucketTagging",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.aws_region}.elasticmapreduce",
          "arn:aws:s3:::${var.aws_region}.elasticmapreduce/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "jenkins_role_policy" {
  name = "${var.prefix}-jenkins-role-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "eks:DescribeAddonConfiguration",
          "eks:ListClusters",
          "eks:DescribeAddonVersions",
          "ec2:DescribeSubnets",
          "eks:RegisterCluster",
          "eks:CreateCluster"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketTagging",
          "kms:Decrypt",
          "kms:Encrypt",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging",
          "kms:DescribeKey",
          "s3:ListBucket",
          "eks:*",
          "ec2:AssignPrivateIpAddresses",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:eks:*:${var.aws_account_num}:nodegroup/*/*/*",
          "arn:aws:eks:*:${var.aws_account_num}:identityproviderconfig/*/*/*/*",
          "arn:aws:eks:*:${var.aws_account_num}:addon/*/*/*",
          "arn:aws:eks:*:${var.aws_account_num}:fargateprofile/*/*/*",
          "arn:aws:eks:*:${var.aws_account_num}:cluster/*",
          "arn:aws:ec2:${var.aws_region}:${var.aws_account_num}:network-interface/*",
          "arn:aws:s3:::${var.data_bucket_name}",
          "arn:aws:s3:::${var.data_bucket_name}/*",
          "arn:aws:s3:::${var.logs_bucket_name}",
          "arn:aws:s3:::${var.logs_bucket_name}/*",
          "arn:aws:s3:::${var.app_bucket_name}",
          "arn:aws:s3:::${var.app_bucket_name}/*",
          "arn:aws:s3:::${var.prefix}-terraform-state",
          "arn:aws:s3:::${var.prefix}-terraform-state/*",
          "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:alias/*",
          "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:key/*"
        ]
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetBucketTagging",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.aws_region}.elasticmapreduce/*",
          "arn:aws:s3:::${var.aws_region}.elasticmapreduce"
        ]
      },
      {
        "Sid" : "ECR",
        "Effect" : "Allow",
        "Action" : [
          "ecr:*",
        ],
        "Resource" : "*"
      },
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.prefix}-ec2-role"
  path = "/"
  # tags = {
  #   Name = "${var.prefix}-ec2-role"
  # }

  # inline_policy {
  #   name = "${var.prefix}-ec2-policy"

  #   policy = jsonencode({
  #     "Version" : "2012-10-17",
  #     "Statement" : [
  #       {
  #         "Sid" : "VisualEditor0",
  #         "Effect" : "Allow",
  #         "Action" : [
  #           "ec2:DescribeInstances",
  #           "ec2:DescribeSubnets"
  #         ],
  #         "Resource" : "*"
  #       },
  #       {
  #         "Sid" : "VisualEditor1",
  #         "Effect" : "Allow",
  #         "Action" : [
  #           "s3:PutObject",
  #           "s3:GetObject",
  #           "s3:GetBucketTagging",
  #           "s3:GetObjectAttributes",
  #           "s3:GetObjectTagging",
  #           "s3:ListBucket",
  #           "s3:DeleteObject",
  #           "ec2:AssignPrivateIpAddresses"
  #         ],
  #         "Resource" : [
  #           "arn:aws:s3:::${var.data_bucket_name}",
  #           "arn:aws:s3:::${var.data_bucket_name}/*",
  #           "arn:aws:s3:::${var.logs_bucket_name}",
  #           "arn:aws:s3:::${var.logs_bucket_name}/*",
  #           "arn:aws:s3:::${var.app_bucket_name}",
  #           "arn:aws:s3:::${var.app_bucket_name}/*",
  #           "arn:aws:ec2:${var.aws_region}:${var.aws_account_num}:network-interface/*"
  #         ]
  #       },
  #       {
  #         "Sid" : "VisualEditor2",
  #         "Effect" : "Allow",
  #         "Action" : [
  #           "kms:Decrypt",
  #           "kms:Encrypt",
  #           "kms:DescribeKey"
  #         ],
  #         "Resource" : [
  #            "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:key/*",
  #            "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:alias/*"
  #         ]
  #       },
  #       {
  #           "Sid": "VisualEditor3",
  #           "Effect": "Allow",
  #           "Action": [
  #               "s3:GetObject",
  #               "s3:GetBucketTagging",
  #               "s3:GetObjectAttributes",
  #               "s3:GetObjectTagging",
  #               "s3:ListBucket"
  #           ],
  #           "Resource": [
  #               "arn:aws:s3:::${var.aws_region}.elasticmapreduce",
  #               "arn:aws:s3:::${var.aws_region}.elasticmapreduce/*"
  #           ]
  #       }
  #     ]
  #   })
  # }

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

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_role_policy.arn
  # managed_policy_arns = [, aws_iam_policy.emr_full_access.arn]
}

resource "aws_iam_role" "jenkins_role" {
  name = "${var.prefix}-jenkins-role"
  path = "/"
  # tags = {
  #   Name = "${var.prefix}-ec2-role"
  # }

  # inline_policy {
  #   name = "${var.prefix}-ec2-policy"

  #   policy = jsonencode({
  #     "Version" : "2012-10-17",
  #     "Statement" : [
  #       {
  #         "Sid" : "VisualEditor0",
  #         "Effect" : "Allow",
  #         "Action" : [
  #           "ec2:DescribeInstances",
  #           "ec2:DescribeSubnets"
  #         ],
  #         "Resource" : "*"
  #       },
  #       {
  #         "Sid" : "VisualEditor1",
  #         "Effect" : "Allow",
  #         "Action" : [
  #           "s3:PutObject",
  #           "s3:GetObject",
  #           "s3:GetBucketTagging",
  #           "s3:GetObjectAttributes",
  #           "s3:GetObjectTagging",
  #           "s3:ListBucket",
  #           "s3:DeleteObject",
  #           "ec2:AssignPrivateIpAddresses"
  #         ],
  #         "Resource" : [
  #           "arn:aws:s3:::${var.data_bucket_name}",
  #           "arn:aws:s3:::${var.data_bucket_name}/*",
  #           "arn:aws:s3:::${var.logs_bucket_name}",
  #           "arn:aws:s3:::${var.logs_bucket_name}/*",
  #           "arn:aws:s3:::${var.app_bucket_name}",
  #           "arn:aws:s3:::${var.app_bucket_name}/*",
  #           "arn:aws:ec2:${var.aws_region}:${var.aws_account_num}:network-interface/*"
  #         ]
  #       },
  #       {
  #         "Sid" : "VisualEditor2",
  #         "Effect" : "Allow",
  #         "Action" : [
  #           "kms:Decrypt",
  #           "kms:Encrypt",
  #           "kms:DescribeKey"
  #         ],
  #         "Resource" : [
  #            "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:key/*",
  #            "arn:aws:kms:${var.aws_region}:${var.aws_account_num}:alias/*"
  #         ]
  #       },
  #       {
  #           "Sid": "VisualEditor3",
  #           "Effect": "Allow",
  #           "Action": [
  #               "s3:GetObject",
  #               "s3:GetBucketTagging",
  #               "s3:GetObjectAttributes",
  #               "s3:GetObjectTagging",
  #               "s3:ListBucket"
  #           ],
  #           "Resource": [
  #               "arn:aws:s3:::${var.aws_region}.elasticmapreduce",
  #               "arn:aws:s3:::${var.aws_region}.elasticmapreduce/*"
  #           ]
  #       }
  #     ]
  #   })
  # }

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

resource "aws_iam_role_policy_attachment" "jenkins_role_policy_attachment" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_role_policy.arn
  # managed_policy_arns = [, aws_iam_policy.emr_full_access.arn]
}
