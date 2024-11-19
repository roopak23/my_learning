

resource "aws_iam_role" "emr_default_role" {
  name = "${var.prefix}-emr-default-role"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
  ]
  tags = {
    Name    = "${var.prefix}-emr-default-role"
    Product = "amap"
  }
  inline_policy {
    name = "${var.prefix}-emr-inline-policy"

    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeSubnets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetBucketTagging",
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey",
                "kms:CreateGrant",
                "s3:GetObjectAttributes",
                "s3:GetObjectTagging",
                "s3:ListBucket",
                "s3:DeleteObject",
                "ec2:AssignPrivateIpAddresses"
            ],
            "Resource": [
            "arn:aws:s3:::${var.data_bucket_name}",
            "arn:aws:s3:::${var.data_bucket_name}/*",
            "arn:aws:s3:::${var.logs_bucket_name}",
            "arn:aws:s3:::${var.logs_bucket_name}/*",
            "arn:aws:s3:::${var.aws_region}.elasticmapreduce/*",
            "arn:aws:s3:::${var.aws_region}.elasticmapreduce",
            "arn:aws:ec2:${var.aws_region}:${var.aws_account_num}:network-interface/*",
            "arn:aws:kms:*:${var.aws_account_num}:key/*"
            ]
        }
    ]
  })
  }
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Principal": {
                "Service": "elasticmapreduce.amazonaws.com"
            },
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role" "emr_autoscaling_role" {
  name = "${var.prefix}-emr-autoscaling-role"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforAutoScalingRole"
  ]
  tags = {
    Name = "${var.prefix}-emr-autoscaling-role"
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

resource "aws_emr_security_configuration" "emr_sc" {
  name = "${var.prefix}-emr-sc"

  configuration = <<EOF
{
  "EncryptionConfiguration": {
    "AtRestEncryptionConfiguration": {
      "LocalDiskEncryptionConfiguration": {
        "EnableEbsEncryption": true,
        "EncryptionKeyProviderType": "AwsKms",
        "AwsKmsKey": "${var.kms_emr_key}"
      }
    },
    "EnableAtRestEncryption": true,
    "EnableInTransitEncryption": false
  }
}
EOF
}
