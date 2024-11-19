

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}"
  tags = {
    Name = "${var.bucket_name}"
  }
}

# ACLs disallowed by Foxtel (burket owner enforced)
# resource "aws_s3_bucket_acl" "data_Acl" {
#   bucket = aws_s3_bucket.bucket.bucket
#   acl    = "private"
# }

resource "aws_s3_bucket_versioning" "bucket-versioning" {
  bucket = aws_s3_bucket.bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_enc" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.bucket.bucket
    policy = jsonencode({
        "Id": "${var.bucket_name}-s3-vpc_policy",
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowSSLRequestsOnly",
                "Effect": "Deny",
                "Principal": "*",
                "Action": "s3:*",
                "Resource": [
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
                ],
                "Condition": {
                    "Bool": {
                        "aws:SecureTransport": "false"
                    }
                }   
            }
        ]
    })
}
