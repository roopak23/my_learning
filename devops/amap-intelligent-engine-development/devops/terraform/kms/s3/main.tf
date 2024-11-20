module "kms_key" {
  source                  = "cloudposse/kms-key/aws"
  version                 = "0.12.1"
  name                    = "${var.prefix}-kms-s3"
  description             = "KMS key for S3"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/${var.prefix}-kms-s3"
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
                }
            ]
        }
   EOF
}
