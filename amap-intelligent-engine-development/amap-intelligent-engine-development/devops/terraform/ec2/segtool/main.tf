
resource "aws_instance" "segtool" {
  ami                     = var.ec2_ami
  subnet_id               = var.segtool_subnet_id # data.terraform_remote_state.vpc.outputs.vpc_public_subnets[0]
  instance_type           = var.ec2_segtool_instance_type
  key_name                = var.ec2_deploy_key_name # data.terraform_remote_state.ec2_common.outputs.deploy_key
  vpc_security_group_ids  = [aws_security_group.ec2_segtool_sg.id]
  disable_api_termination = true
  iam_instance_profile    = var.ec2_instance_profile # data.terraform_remote_state.ec2_common.outputs.instance_profile
  ebs_block_device {
    device_name =  "/dev/xvda"
    encrypted=true
  }
  tags = {
    Name    = "${var.prefix}-ec2-segtool"
    Product = "amap"
  }
}

resource "aws_security_group" "ec2_segtool_sg" {
  name   = "${var.prefix}-ec2-segtool-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-ec2-segtool-sg"
  }
}


# resource "aws_security_group_rule" "segtool_rule_ingress_custom_https_from_private" {
#   description       = "Allow  connect to Segtool from private subnets"
#   security_group_id = aws_security_group.ec2_segtool_sg.id
#   type              = "ingress"
#   from_port         = 7543
#   to_port           = 7543
#   protocol          = "tcp"
#   cidr_blocks       = var.vpc_private_subnets_cidrs
# }



resource "aws_security_group_rule" "segtool_rule_ingress_https_from_private" {
  description       = "Allow  connect to Segtool from private subnets"
  security_group_id = aws_security_group.ec2_segtool_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.vpc_private_subnets_cidrs
}


# resource "aws_security_group_rule" "segtool_rule_ingress_https_from_vpn" {
#   count                    = var.vpn_security_group_id != "" ? 1 : 0
#   description              = "Allot to connect to segtool from VPN"
#   security_group_id        = aws_security_group.ec2_segtool_sg.id
#   type                     = "ingress"
#   from_port                = 7543
#   to_port                  = 7543
#   protocol                 = "tcp"
#   source_security_group_id = var.vpn_security_group_id
# }


# resource "aws_security_group_rule" "segtool_rule_ingress_ssh_from_vpn" {
#   count                    = var.vpn_security_group_id != "" ? 1 : 0
#   description              = "Allot SSH to machinie from VPN"
#   security_group_id        = aws_security_group.ec2_segtool_sg.id
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   source_security_group_id = var.vpn_security_group_id
# }


# resource "aws_security_group_rule" "segtool_rule_ingress_ui_from_vpn" {
#   count                    = var.vpn_security_group_id != "" ? 1 : 0
#   description              = "Allow connect to UI from VPN"
#   security_group_id        = aws_security_group.ec2_segtool_sg.id
#   type                     = "ingress"
#   from_port                = 8095
#   to_port                  = 8095
#   protocol                 = "tcp"
#   source_security_group_id = var.vpn_security_group_id
# }


# resource "aws_security_group_rule" "segtool_rule_ingress_ui_from_private_subnets" {
#   description              = "Allow connect to UI from EKS"
#   security_group_id        = aws_security_group.ec2_segtool_sg.id
#   type                     = "ingress"
#   from_port                = 8095
#   to_port                  = 8095
#   protocol                 = "tcp"
#   cidr_blocks              = var.vpc_private_subnets_cidrs
# }

# ---Outbound---
# resource "aws_security_group_rule" "segtool_rule_egress_internet" {
#   description       = "Allow internet traffic for packages update"
#   security_group_id = aws_security_group.ec2_segtool_sg.id
#   type              = "egress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }



# resource "aws_security_group_rule" "segtool_rule_egress_rds" {
#   description              = "Allow egress to rds DB"
#   security_group_id        = aws_security_group.ec2_segtool_sg.id
#   type                     = "egress"
#   from_port                = var.rds_port
#   to_port                  = var.rds_port
#   protocol                 = "tcp"
#   source_security_group_id = var.rds_security_group
# }

# resource "aws_security_group_rule" "segtool_rule_egress_vpc" {
#   description              = "Allow egress to hive DB"
#   security_group_id        = aws_security_group.ec2_segtool_sg.id
#   type                     = "egress"
#   from_port                = 10000
#   to_port                  = 10000
#   protocol                 = "tcp"
#   cidr_blocks              = var.vpc_private_subnets_cidrs
# }

# # Splunk agents
# resource "aws_security_group_rule" "Splunk_agent" {
#   description              = "Splunk agent"
#   type                     = "egress"
#   protocol                 = "tcp"

#   from_port                = var.splunk_port
#   to_port                  = var.splunk_port
#   cidr_blocks              = var.splunk_agents 

#   security_group_id        = aws_security_group.ec2_segtool_sg.id
# }