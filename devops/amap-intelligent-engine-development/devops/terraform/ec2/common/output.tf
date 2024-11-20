output "deploy_key_name" {
    description = "deploy key name"
    value = aws_key_pair.deployer_access.key_name
}

output "instance_profile" {
    description = "instance profile"
    value = aws_iam_instance_profile.ec2_instance_profile.name
}

output "jenkins_instance_profile" {
    description = "instance profile"
    value = aws_iam_instance_profile.jenkins_instance_profile.name
}

output "instance_profile_arn" {
    description = "instance profile arn"
    value = aws_iam_instance_profile.ec2_instance_profile.arn
}

output "instance_profile_role" {
    description = "instance profile role"
    value = aws_iam_instance_profile.ec2_instance_profile.role
}


#output "sg_ec2" {
#    description = "security group ec2 instance"
#    value = aws_security_group.ec2_sg.id
#}
