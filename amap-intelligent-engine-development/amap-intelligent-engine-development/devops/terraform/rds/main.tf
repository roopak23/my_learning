resource "aws_db_parameter_group" "rds_pg" {
  name   = "${var.prefix}-rds-pg"
  family = "mysql8.0"

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  } 

  # deafault value 8388608 is to small for a query with huge number of elements in IN clause
  # instead of index full scan is used
  parameter {
    name  = "range_optimizer_max_mem_size"
    value = "33554432"
  } 
}

resource "aws_db_instance" "rds" {
  allocated_storage      = 400
  max_allocated_storage  = 1000
  engine                 = "mysql"
  engine_version         = "8.0.35"
  backup_retention_period = var.backup_retention_period
  maintenance_window    = "Sat:15:00-Sat:15:30"
  backup_window         = "16:00-17:00"
  instance_class         = var.instance_type
  username               = var.rds_user
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  storage_encrypted      = true
  storage_type           = "gp3"
  iops                   = "12000"
  apply_immediately      = true
  identifier             = "${var.prefix}-rds"

  # Performance Insights free tier includes:
  #   7 days of performance data history
  #   1 million API requests per month
  performance_insights_enabled  = true
  performance_insights_retention_period  = 7

  parameter_group_name   = aws_db_parameter_group.rds_pg.name

  tags = {
    Name = "${var.prefix}-rds"
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "${var.prefix}-rds-pro-subnet-group"
  subnet_ids = [var.vpc_private_subnets_ids[0],var.vpc_private_subnets_ids[1]]
  tags = {
    Name = "${var.prefix}-rds-pro-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.prefix}-rds-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-rds-sg"
  }
}

resource "aws_security_group" "lambda_sg" {
  name   = "${var.prefix}-lambda-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-lambda-sg"
  }
}

resource "aws_security_group_rule" "rds_rule_eks" {
  description              = "Allow EKS cluster  connect to RDS"
  security_group_id        = aws_security_group.rds_sg.id
  type                     = "ingress"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "tcp"
  source_security_group_id = var.eks_security_groups
}

resource "aws_security_group_rule" "rds_rule_emr" {
  description       = "Allow EMR cluster  connect to RDS"
  security_group_id = aws_security_group.rds_sg.id
  type              = "ingress"
  from_port         = var.rds_port
  to_port           = var.rds_port
  protocol          = "tcp"
  cidr_blocks = [
  var.vpc_private_subnets_cidrs[0]]
}


resource "aws_security_group_rule" "rds_rule_from_vpn" {
  description              = "Allow access from VPN(CITRIX)"
  security_group_id        = aws_security_group.rds_sg.id
  type                     = "ingress"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "tcp"
  cidr_blocks              = var.citrix_cidrs 
}

resource "aws_security_group_rule" "rds_ingress_rule_lambda" {
  description       = "Allow access from lambda"
  security_group_id = aws_security_group.lambda_sg.id
  type              = "ingress"
  from_port         = var.rds_port
  to_port           = var.rds_port
  protocol          = "tcp"
  cidr_blocks       = ["127.0.0.1/32"]
}

resource "aws_security_group_rule" "rds_egress_rule_lambda_https" {
  description       = ""
  security_group_id = aws_security_group.lambda_sg.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rds_egress_rule_lambda_http" {
  description       = ""
  security_group_id = aws_security_group.lambda_sg.id
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rds_egress_rule_lambda_vpc" {
  description       = ""
  security_group_id = aws_security_group.lambda_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = [var.vpc_cidr_block]
}
