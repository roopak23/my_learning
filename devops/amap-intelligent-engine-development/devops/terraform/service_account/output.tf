output "service_account_arn" {
  description = "Service account role arn"
  value = aws_iam_role.service_account_role.arn
}