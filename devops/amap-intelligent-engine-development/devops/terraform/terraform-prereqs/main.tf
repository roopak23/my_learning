variable env{}
variable site{}
variable aws_region{}

locals {
  default_separator = "-"
  prefix            = lower(join(local.default_separator, [var.site, var.env]))

}



provider "aws" {
    region = var.aws_region
}


resource "aws_s3_bucket" "s3_backend" {
    bucket = "${local.prefix}-terraform-state"
    tags = {
        Name = "${local.prefix}-terraform-state"
    }  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-encryption" {
  bucket = aws_s3_bucket.s3_backend.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "bucket-versioning" {
  bucket = aws_s3_bucket.s3_backend.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "require-ssl" {
  bucket = aws_s3_bucket.s3_backend.id
  policy = data.aws_iam_policy_document.require-ssl.json
}

data "aws_iam_policy_document" "require-ssl" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    effect = "Deny"

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    resources = [
      aws_s3_bucket.s3_backend.arn,
      "${aws_s3_bucket.s3_backend.arn}/*",
    ]
  }
}