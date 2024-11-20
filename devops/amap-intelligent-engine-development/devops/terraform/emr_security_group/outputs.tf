output "emr_sg_id" {
    description = "emr sg id"
    value = aws_security_group.emr_additional_sg.id
}