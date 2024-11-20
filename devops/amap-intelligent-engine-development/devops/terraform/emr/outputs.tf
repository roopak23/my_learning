output "emr_default_role" {
    value = aws_iam_role.emr_default_role.name
}

output "emr_autoscaling_role" {
    value = aws_iam_role.emr_autoscaling_role.name
}