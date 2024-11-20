    module "kms_key" {
      source = "cloudposse/kms-key/aws"
      version = "0.12.1"
      name                    = "${var.prefix}-kms-sns"
      description             = "KMS key for Ssns3"
      deletion_window_in_days = 10
      enable_key_rotation     = true
      alias                   = "alias/${var.prefix}-kms-sns"
      policy                  = <<EOF
      {
            "Version": "2012-10-17",
            "Id": "key-default-1",
            "Statement": [
                {
                    "Sid": "Enable IAM User Permissions",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::${var.aws_account_id}:root"
                    },
                    "Action": "kms:*",
                    "Resource": "*"
                },
                {
                  "Sid": "Allow use of the key",
                  "Effect": "Allow",
                  "Principal": { "Service": "cloudwatch.amazonaws.com" },
                  "Action": [
                      "kms:Encrypt",
                      "kms:Decrypt",
                      "kms:ReEncrypt*",
                      "kms:GenerateDataKey*",
                      "kms:DescribeKey"
                  ],
                  "Resource": "*"
              }
            ]
        }
      EOF
    }

               