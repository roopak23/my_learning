

locals {
  data_bucket_name = module.s3_data.bucket_name
  objects_prefix   = "data/outbound/crm_analytics"
}

resource "aws_iam_user" "crm_analytics" {
  name = "crm_analytics"
}

resource "aws_iam_user_policy" "crm_analytisc_policy" {
  name = "${var.prefix}-crm-analytics-inline-policy"
  user = aws_iam_user.crm_analytics.name
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ReadBucketLevel",
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.data_bucket_name}"
          ]
        },
        {
          "Sid" : "ReadObjectLevel",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.data_bucket_name}/${local.objects_prefix}/*",
          ]
        }
      ]
    }
  )
}
