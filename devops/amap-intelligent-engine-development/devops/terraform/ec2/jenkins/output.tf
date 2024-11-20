output "ec2_jenkins_private_ip" {
    description     = "ec2 jenkins instance"
    value           = aws_instance.jenkins.private_ip
}
