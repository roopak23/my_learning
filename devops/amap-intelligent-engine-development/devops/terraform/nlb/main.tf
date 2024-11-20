

resource "aws_lb" "nlb" {
  name                             = "${var.prefix}-int-nlb"
  internal                         = true
  load_balancer_type               = "network"
  security_groups                  = [aws_security_group.nlb_int_sg.id]
  subnets                          = var.vpc_private_subnets_ids
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.prefix}-int-nlb"
  }
}

# Create the listeners
resource "aws_lb_listener" "nlb-https-listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_https_target_group.arn
  }
}


# Create the listeners
resource "aws_lb_listener" "nlb-http-listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_http_target_group.arn
  }
}
resource "aws_lb_listener" "nlb-ssh-listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "22"
  protocol          = "TCP"
  # ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  # certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_ssh_target_group.arn
  }
}

resource "aws_lb_target_group" "nlb_https_target_group" {
  port        = "443"
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  depends_on = [
    aws_lb.nlb
  ]

  # lifecycle {
  #   create_before_destroy = false
  # }
}

resource "aws_lb_target_group" "nlb_http_target_group" {
  port        = "80"
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  depends_on = [
    aws_lb.nlb
  ]

  # lifecycle {
  #   create_before_destroy = false
  # }
}

resource "aws_lb_target_group" "nlb_ssh_target_group" {
  port        = "22"
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  depends_on = [
    aws_lb.nlb
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "nlb_https_attachment" {
  target_group_arn  = aws_lb_target_group.nlb_https_target_group.arn
  target_id         = var.jenkinsip
  availability_zone = "ap-southeast-2b"
  port              = "8080"
}

resource "aws_lb_target_group_attachment" "nlb_http_attachment" {
  target_group_arn  = aws_lb_target_group.nlb_http_target_group.arn
  target_id         = var.jenkinsip
  availability_zone = "ap-southeast-2b"
  port              = "8080"
}

resource "aws_lb_target_group_attachment" "nlb_ssh_attachment" {
  target_group_arn  = aws_lb_target_group.nlb_ssh_target_group.arn
  target_id         = var.jenkinsip
  availability_zone = "ap-southeast-2b"
  port              = "22"
}

resource "aws_security_group" "nlb_int_sg" {
  name   = "${var.prefix}-nlb-int-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-nlb-int-sg"
  }
}

resource "aws_security_group_rule" "nlb_access_jenkins_https" {

  # count                    = var.vpn_security_group_id != "" ? 1 : 0
  description       = "Allot to connect to jenkins HTTPS"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
}


resource "aws_security_group_rule" "nlb_access_jenkins_http" {

  # count                    = var.vpn_security_group_id != "" ? 1 : 0
  description       = "Allot to connect to jenkins HTTPS"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "nlb_access_jenkins_ssh" {

  # count                    = var.vpn_security_group_id != "" ? 1 : 0
  description       = "Allot to connect to jenkins SSH"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
}


resource "aws_security_group_rule" "nlb_access_jenkins_https_citrix" {
  description       = "Allow to connect to NLB from citrix Workspace"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.citrix_cidrs
}

resource "aws_security_group_rule" "nlb_access_jenkins_http_citrix" {
  description       = "Allow to connect to NLB from citrix Workspace"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.citrix_cidrs
}

resource "aws_security_group_rule" "nlb_access_jenkins_ssh_citrix" {
  description       = "Allow to connect to NLB from citrix Workspace"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.citrix_cidrs
}


resource "aws_security_group_rule" "nlb_egress_jenkins_https" {

  # count                    = var.vpn_security_group_id != "" ? 1 : 0
  description       = "Access to jenkins HTTPS"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "egress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "nlb_egress_jenkins_ssh" {

  # count                    = var.vpn_security_group_id != "" ? 1 : 0
  description       = "Access to jenkins SSH"
  security_group_id = aws_security_group.nlb_int_sg.id
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
}
