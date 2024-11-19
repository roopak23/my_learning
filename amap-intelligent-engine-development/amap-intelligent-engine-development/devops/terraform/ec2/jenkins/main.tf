
resource "aws_instance" "jenkins" {
  ami                     = var.ec2_ami
  subnet_id               = var.subnet_id
  instance_type           = var.instance_type
  key_name                = var.ec2_deploy_key_name
  vpc_security_group_ids  = [aws_security_group.ec2_jenkins.id]
  disable_api_termination = true
  iam_instance_profile    = var.jenkins_instance_profile # data.terraform_remote_state.ec2_common.outputs.instance_profile
  root_block_device {
    encrypted   = true
    volume_size = 29
  }
  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name    = "${var.prefix}-ec2-jenkins"
    Product = "amap"
  }
  user_data = file("${path.module}/startup.sh")
}


resource "aws_security_group" "ec2_jenkins" {
  name   = "${var.prefix}-ec2-jenkins-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-ec2-jenkins-sg"
  }
}



# resource "aws_security_group_rule" "jenkins_rule_ingress_http_from_vpn" {
#   description              = "Allow  connect to Segtool from private subnets"
#   security_group_id        = aws_security_group.ec2_jenkins.id
#   type                     = "ingress"
#   from_port                = 8080
#   to_port                  = 8080
#   protocol                 = "tcp"
#   source_security_group_id = var.vpn_security_group_id
# }


# resource "aws_security_group_rule" "jenkins_rule_ingress_ssh_from_vpn" {
#   count                    = var.vpn_security_group_id != "" ? 1 : 0
#   description              = "Allot SSH to machinie from VPN"
#   security_group_id        = aws_security_group.ec2_jenkins.id
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   source_security_group_id = var.vpn_security_group_id
# }

resource "aws_security_group_rule" "jenkins_rule_ingress_http_from_vpc" {
  description              = "Allow  connect to Jenkins from VPC"
  security_group_id        = aws_security_group.ec2_jenkins.id
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  cidr_blocks              = [var.vpc_cidr_block]
}


resource "aws_security_group_rule" "jenkins_rule_ingress_ssh_from_vpc" {
  description              = "Allot SSH to Jenkins from VPC"
  security_group_id        = aws_security_group.ec2_jenkins.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = [var.vpc_cidr_block]
}

# ---Outbound---
resource "aws_security_group_rule" "jeknins_rule_egress_internet_https" {
  description       = "Allow internet traffic for packages update"
  security_group_id = aws_security_group.ec2_jenkins.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "jeknins_rule_egress_internet_http" {
  description       = "Allow internet traffic for packages update"
  security_group_id = aws_security_group.ec2_jenkins.id
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}


