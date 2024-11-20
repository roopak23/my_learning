resource "aws_lb_target_group" "segtool-tg" {
  name        = "${var.prefix}-segtool-tg"
  port        = 7543
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = var.vpc_id
}


resource "aws_lb_target_group_attachment" "segtool-tg-attachment" {
  target_group_arn = aws_lb_target_group.segtool-tg.arn
  target_id        = var.segtool_ip
  port             = 7543
}

resource "aws_lb" "alb" {
  name               = "${var.prefix}-int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_int_sg.id]
  subnets            = var.vpc_private_subnets_ids

  tags = {
    Name = "${var.prefix}-int-alb"
  }
}

# Create the listener
resource "aws_lb_listener" "alb-internal-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "alb-segtool-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "7543"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "segtool-listener-rule" {
  listener_arn = aws_lb_listener.alb-segtool-listener.arn
  priority     = 102
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.segtool-tg.arn
  }

  condition {
    host_header {
      values = ["${var.segtool_site}"]
    }
  }
}

resource "aws_security_group" "alb_int_sg" {
  name   = "${var.prefix}-alb-int-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-alb-int-sg"
  }
}

# resource "aws_security_group_rule" "alb_rule_ingress_https_from_vpn" {
 
#  # count                    = var.vpn_security_group_id != "" ? 1 : 0
#   description              = "Allot to connect to segtool from VPN"
#   security_group_id        = aws_security_group.alb_int_sg.id
#   type                     = "ingress"
#   from_port                = 7543
#   to_port                  = 7543
#   protocol                 = "tcp"
#   source_security_group_id = var.vpn_security_group_id
# }



resource "aws_security_group_rule" "alb_rule_egress_to_segtool" {
  #count                    = var.segtool_sec_group_id != "" ? 1 : 0
  description              = "Allot to connect to segtool"
  security_group_id        = aws_security_group.alb_int_sg.id
  type                     = "egress"
  from_port                = 7543
  to_port                  = 7543
  protocol                 = "tcp"
  source_security_group_id = var.segtool_sec_group_id
}


resource "aws_security_group_rule" "alb_rule_egress_to_segtool_https" {
  #count                    = var.segtool_sec_group_id != "" ? 1 : 0
  description              = "Allot to connect to segtool"
  security_group_id        = aws_security_group.alb_int_sg.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.segtool_sec_group_id
}



