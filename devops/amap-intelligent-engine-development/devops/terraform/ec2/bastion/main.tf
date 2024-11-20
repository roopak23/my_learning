
resource "aws_instance" "test" {
  ami                     = var.ec2_ami
  subnet_id               = "subnet-0560ef13a4b1c1b19" # var.vpc_public_subnet_ids[1] # data.terraform_remote_state.vpc.outputs.vpc_public_subnets[0]
  instance_type           = "t2.nano"
  key_name                = var.ec2_deploy_key_name # data.terraform_remote_state.ec2_common.outputs.deploy_key
  vpc_security_group_ids  = [aws_security_group.ec2_test_sg.id]
  disable_api_termination = true
  iam_instance_profile    = var.ec2_instance_profile # data.terraform_remote_state.ec2_common.outputs.instance_profile
  associate_public_ip_address = true
  ebs_block_device {
    device_name =  "/dev/xvda"
    encrypted=true
  }
  tags = {
    Name    = "${var.prefix}-ec2-test"
    Product = "amap"
  }
  lifecycle {
    ignore_changes = [ 
      associate_public_ip_address,
     ]
  }
}

resource "aws_security_group" "ec2_test_sg" {
  name   = "${var.prefix}-ec2-test-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-ec2-test-sg"
  }
}


# resource "aws_security_group_rule" "test_rule_ingress_custom_https_from_private" {
#   description       = "Allow  connect to test from private subnets"
#   security_group_id = aws_security_group.ec2_test_sg.id
#   type              = "ingress"
#   from_port         = 7543
#   to_port           = 7543
#   protocol          = "tcp"
#   cidr_blocks       = var.vpc_private_subnets_cidrs
# }



resource "aws_security_group_rule" "test_rule_ingress_ssh_from_ext" {
  description       = "Allow  connect to test from specified address"
  security_group_id = aws_security_group.ec2_test_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["77.237.23.31/32"]
}


# resource "aws_eip" "test_eip" {
#     vpc = true
#     tags = {
#     Name = "${var.prefix}-test-eip-dev"
#     }
# }

# resource "aws_eip_association" "test_eip_association" {
#     instance_id = aws_instance.test.id
#     allocation_id = aws_eip.test_eip.id
# }
