output "bucket_name" {
    description = "s3 info"
    value = aws_s3_bucket.bucket.bucket
}

output "bucket_arn" {
    description = "s3 arn"
    value = aws_s3_bucket.bucket.arn
}